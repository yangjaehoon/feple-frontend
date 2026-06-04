import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// GET 응답 캐시.
/// - 1차: 앱 메모리 (동기 조회, 앱 재시작 시 초기화)
/// - 2차: SharedPreferences 인스턴스 (init() 후 동기 조회 가능 — 내부가 메모리 맵)
/// - 3차: SharedPreferences 비동기 (init() 전 fallback)
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
    // 거의 바뀌지 않는 정적 콘텐츠
    if (url.contains('/songs') ||
        url.contains('/photos')) {
      return 30 * 24 * 60 * 60 * 1000; // 30일
    }
    // 기본값: 페스티벌 목록/상세, 아티스트, 유저 프로필 등
    return 7 * 24 * 60 * 60 * 1000;                                      // 7일
  }

  static bool _expired(String url, int ts) =>
      DateTime.now().millisecondsSinceEpoch - ts > _ttlFor(url);

  /// main()에서 AppPreferences.init() 직후 호출.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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
      final ts = map['ts'] as int;
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

  /// 비동기 조회 — getSync() 실패 시 SharedPreferences를 직접 읽는 fallback
  static Future<dynamic> get(String url) async {
    final sync = getSync(url);
    if (sync != null) return sync;

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(url));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ts = map['ts'] as int;
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
