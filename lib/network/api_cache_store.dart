import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DioClient 인터셉터에 연결되는 범용 GET 응답 캐시 (URL 문자열 → raw JSON).
/// 모든 GET 요청에 자동 적용되며 호출부 수정이 필요 없다 (SWR 스타일).
/// - 1차: 앱 메모리 (동기 조회, 앱 재시작 시 초기화, LRU 상한 있음)
/// - 2차: SharedPreferences 인스턴스 (init() 후 동기 조회 가능 — 내부가 메모리 맵)
/// - 3차: SharedPreferences 비동기 (init() 전 fallback)
///
/// [FestivalCacheService](../service/festival_cache_service.dart)와는 다른
/// 캐시다 — 그쪽은 페스티벌 화면이 프리패치/오프라인 폴백을 위해 명시적으로
/// 호출하는 타입 있는 모델 캐시이고, 이 클래스는 인터셉터가 자동으로 관리하는
/// 범용 캐시다. 같은 데이터가 양쪽에 중복 저장될 수 있으며 의도된 것이다.
class ApiCacheStore {
  static const _prefix = 'api_cache_';

  // 메모리 캐시 LRU 상한 — 커서 페이지네이션(?cursor=...)마다 새 URL 키가
  // 생기므로 상한이 없으면 긴 세션에서 무한 증가한다.
  static const _maxMemEntries = 256;
  // 영속 캐시 엔트리 수 상한 — SharedPreferences는 앱 시작 시 전체를 메모리에
  // 로드하므로 엔트리가 계속 쌓이면 콜드스타트가 앱 수명에 비례해 느려진다.
  static const _maxPersistedEntries = 400;
  // 개별 응답이 이 크기를 넘으면 SharedPreferences에 쓰지 않고 메모리 캐시로만
  // 유지한다 (presigned URL 포함 대형 리스트 응답이 디스크에 쌓이는 것 방지).
  static const _maxPersistedEntryBytes = 256 * 1024;

  static final Map<String, _Entry> _mem = {};
  static SharedPreferences? _prefs;

  static String _key(String url) => '$_prefix$url';

  /// TTL/무효화 매칭은 쿼리스트링을 제외한 path 기준으로 수행한다 —
  /// `?keyword=/search` 처럼 쿼리에 들어간 문자열이 엔드포인트 패턴에
  /// 잘못 매치되는 것을 막는다.
  static String _pathOf(String url) {
    final path = Uri.tryParse(url)?.path;
    return (path == null || path.isEmpty) ? url : path;
  }

  // 엔드포인트 특성별 TTL(ms) 테이블 — 위에서부터 첫 매치 우선.
  // 새 엔드포인트 TTL 추가 시 이 표에 행만 추가하면 됨 (분기 추가 불필요).
  static const _ttlTable = <(List<String> patterns, int ttlMs)>[
    (['/notifications'], 2 * 60 * 1000), // 실시간성 높은 상태값 — 2분
    // 신규 등록된 아티스트/페스티벌이 기본 TTL(7일)까지 검색에 안 잡히면
    // 안 되므로 짧게 유지 — 10분
    (['/search'], 10 * 60 * 1000),
    (['/liked', '/follow', '/attending', '/scraped'], 10 * 60 * 1000), // 10분
    (['/posts', '/comments'], 30 * 60 * 1000), // 게시글·댓글 — 30분
    (['/weather'], 3 * 60 * 60 * 1000), // 3시간
    // 페스티벌 당일 콘텐츠 (타임테이블, 세트리스트, 스케줄) — 12시간
    (['/timetable', '/setlist', '/schedule'], 12 * 60 * 60 * 1000),
    // 텍스트 데이터 — presigned URL 없음 — 30일
    (['/songs'], 30 * 24 * 60 * 60 * 1000),
    // presigned URL 포함 — 백엔드 TTL(7일)보다 짧게 유지 — 6시간
    (['/photos'], 6 * 60 * 60 * 1000),
    // 상태 변경 + presigned URL — 1시간
    (['/certifications'], 60 * 60 * 1000),
  ];

  // 기본값: 페스티벌 목록/상세, 아티스트, 유저 프로필 등 — 7일
  static const _defaultTtlMs = 7 * 24 * 60 * 60 * 1000;

  /// 엔드포인트 특성에 맞는 TTL 반환 (단위: ms)
  static int _ttlFor(String url) {
    final path = _pathOf(url);
    for (final (patterns, ttlMs) in _ttlTable) {
      if (patterns.any(path.contains)) return ttlMs;
    }
    return _defaultTtlMs;
  }

  static bool _expired(String url, int ts) =>
      DateTime.now().millisecondsSinceEpoch - ts > _ttlFor(url);

  /// main()에서 AppPreferences.init() 직후 호출.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _pruneAndCapPersisted();
  }

  /// 테스트 전용 — 메모리 캐시와 _prefs 초기화
  @visibleForTesting
  static void clearForTesting() {
    _mem.clear();
    _prefs = null;
  }

  static Future<void> put(String url, dynamic data) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    _memPut(url, _Entry(data, ts));
    try {
      final encoded = jsonEncode({'data': data, 'ts': ts});
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (encoded.length > _maxPersistedEntryBytes) {
        // 대형 응답 — 메모리 캐시로만 유지하고 기존 영속본은 제거
        await prefs.remove(_key(url));
        return;
      }
      await prefs.setString(_key(url), encoded);
    } catch (_) {}
  }

  /// 동기 조회 — _mem → _prefs 순서.
  static dynamic getSync(String url) {
    // 1차: 메모리
    final e = _mem[url];
    if (e != null) {
      if (_expired(url, e.ts)) {
        _mem.remove(url);
      } else {
        _memPut(url, e); // LRU: 최근 사용으로 이동
        return e.data;
      }
    }

    // 2차: SharedPreferences 인스턴스 (init() 후 사실상 동기)
    final prefs = _prefs;
    if (prefs == null) return null;
    final raw = prefs.getString(_key(url));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (map['ts'] as num).toInt();
      if (_expired(url, ts)) {
        prefs.remove(_key(url));
        return null;
      }
      _memPut(url, _Entry(map['data'], ts));
      return map['data'];
    } catch (_) {
      return null;
    }
  }

  /// 뮤테이션(POST/PUT/PATCH/DELETE) 성공 시 관련 캐시 무효화.
  /// DioClient의 onResponse에서 GET이 아닌 성공 응답에 호출됨.
  static Future<void> invalidateFor(String requestUrl) async {
    final patterns = _invalidationPatterns(requestUrl);
    for (final p in patterns) {
      _mem.removeWhere((url, _) => url.contains(p));
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        final keys = prefs
            .getKeys()
            .where((k) => k.startsWith(_prefix) && k.contains(p))
            .toList();
        for (final k in keys) {
          await prefs.remove(k);
        }
      } catch (_) {}
    }
  }

  // 뮤테이션 URL(path) → 무효화할 캐시 URL 패턴 테이블 — 위에서부터 첫 매치 우선.
  // 유저 차단(/users/(\d+)/block)처럼 캐시된 게시글·댓글 목록도 함께
  // 무효화해야 하는 경우(차단 전 캐시가 TTL 동안 남아 차단한 유저의
  // 콘텐츠가 계속 보이는 것을 방지) 여러 패턴을 함께 반환한다.
  // 게시글 좋아요/스크랩은 상세(/posts/{id})의 likeCount·scrapCount도 바뀌므로
  // 상세 캐시까지 함께 무효화한다 (PostService.fetchCounts가 상세를 재조회).
  // 새 뮤테이션 엔드포인트 추가 시 이 표에 행만 추가하면 됨.
  static final _invalidationTable =
      <(RegExp pattern, List<String> Function(RegExpMatch) invalidations)>[
    (RegExp(r'/festivals/(\d+)/like'),
        (m) => ['/festivals/${m.group(1)}/liked', '/liked-festivals']),
    (RegExp(r'/festivals/(\d+)/attending'),
        (m) => ['/festivals/${m.group(1)}/attending']),
    (RegExp(r'/festivals/(\d+)/artists/'),
        (m) => ['/festivals/${m.group(1)}/setlist']),
    (RegExp(r'/festivals$'), (_) => ['/festivals']),
    (RegExp(r'/artists/(\d+)/follow'),
        (m) => ['/artists/${m.group(1)}/follow', '/following']),
    (RegExp(r'/artists/(\d+)/photos'),
        (m) => ['/artists/${m.group(1)}/photos']),
    (RegExp(r'/song-requests'), (_) => ['/song-requests']),
    (RegExp(r'/posts/(\d+)/like'), (m) =>
        ['/posts/${m.group(1)}/liked', '/liked-posts', '/posts/${m.group(1)}']),
    (RegExp(r'/posts/(\d+)/scrap'), (m) =>
        ['/posts/${m.group(1)}/scraped', '/scrapped', '/posts/${m.group(1)}']),
    (RegExp(r'/view'), (_) => const <String>[]), // 조회수 — 무효화 불필요
    (RegExp(r'/posts'), (_) => ['/posts']),
    (RegExp(r'/comments/(\d+)/like'), (m) => ['/comments/${m.group(1)}']),
    (RegExp(r'/comments'), (_) => ['/comments']),
    (RegExp(r'/notifications'), (_) => ['/notifications']),
    (RegExp(r'/certifications'), (_) => ['/certifications']),
    (RegExp(r'/users/(\d+)/block'), (m) =>
        ['/users/${m.group(1)}', '/users/blocked', '/posts', '/comments']),
    (RegExp(r'/users/(me|\d+)'), (m) => ['/users/${m.group(1)}']),
  ];

  static List<String> _invalidationPatterns(String url) {
    final path = _pathOf(url);
    for (final (pattern, invalidations) in _invalidationTable) {
      final m = pattern.firstMatch(path);
      if (m != null) return invalidations(m);
    }
    return [];
  }

  /// 비동기 조회 — getSync() 실패 시 SharedPreferences를 직접 읽는 fallback
  static Future<dynamic> get(String url) async {
    final sync = getSync(url);
    if (sync != null) return sync;

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(url));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (map['ts'] as num).toInt();
      if (_expired(url, ts)) {
        await prefs.remove(_key(url));
        return null;
      }
      _memPut(url, _Entry(map['data'], ts));
      return map['data'];
    } catch (_) {
      return null;
    }
  }

  /// LRU 삽입 — 이미 있으면 제거 후 재삽입해 '최근 사용' 위치(맨 뒤)로 옮기고,
  /// 상한 초과 시 가장 오래 안 쓰인 항목(맨 앞)을 버린다.
  static void _memPut(String url, _Entry entry) {
    _mem.remove(url);
    _mem[url] = entry;
    if (_mem.length > _maxMemEntries) {
      _mem.remove(_mem.keys.first);
    }
  }

  /// 앱 시작 시 1회 — 만료된 영속 캐시를 정리하고, 그래도 상한을 넘으면
  /// 오래된 순으로 잘라낸다.
  static Future<void> _pruneAndCapPersisted() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final keys =
          prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      final survivors = <({String key, int ts})>[];
      for (final k in keys) {
        final raw = prefs.getString(k);
        int? ts;
        if (raw != null) {
          try {
            ts = ((jsonDecode(raw) as Map<String, dynamic>)['ts'] as num)
                .toInt();
          } catch (_) {
            ts = null;
          }
        }
        final url = k.substring(_prefix.length);
        if (ts == null || _expired(url, ts)) {
          await prefs.remove(k);
        } else {
          survivors.add((key: k, ts: ts));
        }
      }
      if (survivors.length > _maxPersistedEntries) {
        survivors.sort((a, b) => a.ts.compareTo(b.ts)); // 오래된 것 먼저
        final removeCount = survivors.length - _maxPersistedEntries;
        for (var i = 0; i < removeCount; i++) {
          await prefs.remove(survivors[i].key);
        }
      }
    } catch (_) {}
  }
}

class _Entry {
  final dynamic data;
  final int ts;
  const _Entry(this.data, this.ts);
}
