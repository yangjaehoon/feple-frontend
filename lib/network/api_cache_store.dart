import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DioClient 인터셉터에 연결되는 범용 GET 응답 캐시 (URL 문자열 → raw JSON).
/// 모든 GET 요청에 자동 적용되며 호출부 수정이 필요 없다 (SWR 스타일).
/// - 1차: 앱 메모리 (동기 조회, 앱 재시작 시 초기화)
/// - 2차: SharedPreferences 인스턴스 (init() 후 동기 조회 가능 — 내부가 메모리 맵)
/// - 3차: SharedPreferences 비동기 (init() 전 fallback)
///
/// [FestivalCacheService](../service/festival_cache_service.dart)와는 다른
/// 캐시다 — 그쪽은 페스티벌 화면이 프리패치/오프라인 폴백을 위해 명시적으로
/// 호출하는 타입 있는 모델 캐시이고, 이 클래스는 인터셉터가 자동으로 관리하는
/// 범용 캐시다. 같은 데이터가 양쪽에 중복 저장될 수 있으며 의도된 것이다.
class ApiCacheStore {
  static const _prefix = 'api_cache_';

  static final Map<String, _Entry> _mem = {};
  static SharedPreferences? _prefs;

  static String _key(String url) => '$_prefix$url';

  /// 엔드포인트 특성에 맞는 TTL 반환 (단위: ms)
  static int _ttlFor(String url) {
    // 실시간성 높은 상태값
    if (url.contains('/notifications')) return 2 * 60 * 1000;           // 2분
    if (url.contains('/liked') ||
        url.contains('/follow') ||
        url.contains('/attending') ||
        url.contains('/scraped')) {
      return 10 * 60 * 1000; // 10분
    }
    // 게시글·댓글
    if (url.contains('/posts') ||
        url.contains('/comments')) {
      return 30 * 60 * 1000; // 30분
    }
    // 날씨
    if (url.contains('/weather')) return 3 * 60 * 60 * 1000;            // 3시간
    // 페스티벌 당일 콘텐츠 (타임테이블, 세트리스트, 스케줄)
    if (url.contains('/timetable') ||
        url.contains('/setlist') ||
        url.contains('/schedule')) {
      return 12 * 60 * 60 * 1000; // 12시간
    }
    // 텍스트 데이터 — presigned URL 없음
    if (url.contains('/songs')) return 30 * 24 * 60 * 60 * 1000;        // 30일
    // presigned URL 포함 — 백엔드 TTL(7일)보다 짧게 유지
    if (url.contains('/photos')) return 6 * 60 * 60 * 1000;             // 6시간
    if (url.contains('/certifications')) return 60 * 60 * 1000;         // 1시간 (상태 변경 + presigned URL)
    // 기본값: 페스티벌 목록/상세, 아티스트, 유저 프로필 등
    return 7 * 24 * 60 * 60 * 1000;                                      // 7일
  }

  static bool _expired(String url, int ts) =>
      DateTime.now().millisecondsSinceEpoch - ts > _ttlFor(url);

  /// main()에서 AppPreferences.init() 직후 호출.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 테스트 전용 — 메모리 캐시와 _prefs 초기화
  @visibleForTesting
  static void clearForTesting() {
    _mem.clear();
    _prefs = null;
  }

  static Future<void> put(String url, dynamic data) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    _mem[url] = _Entry(data, ts);
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_key(url), jsonEncode({'data': data, 'ts': ts}));
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
      _mem[url] = _Entry(map['data'], ts);
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

  static List<String> _invalidationPatterns(String url) {
    RegExpMatch? m;

    // 페스티벌 좋아요
    m = RegExp(r'/festivals/(\d+)/like').firstMatch(url);
    if (m != null) return ['/festivals/${m.group(1)!}/liked', '/liked-festivals'];

    // 페스티벌 참석
    m = RegExp(r'/festivals/(\d+)/attending').firstMatch(url);
    if (m != null) return ['/festivals/${m.group(1)!}/attending'];

    // 세트리스트 수정
    m = RegExp(r'/festivals/(\d+)/artists/').firstMatch(url);
    if (m != null) return ['/festivals/${m.group(1)!}/setlist'];

    // 페스티벌 제출
    if (RegExp(r'/festivals$').hasMatch(url)) return ['/festivals'];

    // 아티스트 팔로우
    m = RegExp(r'/artists/(\d+)/follow').firstMatch(url);
    if (m != null) return ['/artists/${m.group(1)!}/follow', '/following'];

    // 아티스트 사진 삭제
    m = RegExp(r'/artists/(\d+)/photos').firstMatch(url);
    if (m != null) return ['/artists/${m.group(1)!}/photos'];

    // 곡 신청
    if (url.contains('/song-requests')) return ['/song-requests'];

    // 게시글 좋아요
    m = RegExp(r'/posts/(\d+)/like').firstMatch(url);
    if (m != null) return ['/posts/${m.group(1)!}/liked', '/liked-posts'];

    // 게시글 스크랩
    m = RegExp(r'/posts/(\d+)/scrap').firstMatch(url);
    if (m != null) return ['/posts/${m.group(1)!}/scraped', '/scrapped'];

    // 게시글 조회수 (캐시 무효화 불필요)
    if (url.contains('/view')) return [];

    // 게시글 수정/삭제
    if (url.contains('/posts')) return ['/posts'];

    // 댓글 좋아요
    m = RegExp(r'/comments/(\d+)/like').firstMatch(url);
    if (m != null) return ['/comments/${m.group(1)!}'];

    // 댓글 작성/삭제
    if (url.contains('/comments')) return ['/comments'];

    // 알림 읽음/삭제
    if (url.contains('/notifications')) return ['/notifications'];

    // 인증
    if (url.contains('/certifications')) return ['/certifications'];

    // 유저 차단/차단 해제
    m = RegExp(r'/users/(\d+)/block').firstMatch(url);
    if (m != null) return ['/users/${m.group(1)!}', '/users/blocked'];

    // 유저 프로필 수정
    m = RegExp(r'/users/(me|\d+)').firstMatch(url);
    if (m != null) return ['/users/${m.group(1)!}'];

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
      _mem[url] = _Entry(map['data'], ts);
      return map['data'];
    } catch (_) {
      return null;
    }
  }
}

class _Entry {
  final dynamic data;
  final int ts;
  const _Entry(this.data, this.ts);
}
