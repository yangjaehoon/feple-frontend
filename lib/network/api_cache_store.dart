import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// GET 응답 캐시.
/// - 1차: 앱 메모리 (동기 조회, 앱 재시작 시 초기화)
/// - 2차: SharedPreferences 인스턴스 (init() 후 동기 조회 가능 — 내부가 메모리 맵)
/// - 3차: SharedPreferences 비동기 (init() 전 fallback)
class ApiCacheStore {
  static const _prefix = 'api_cache_';
  static const int _maxAgeMs = 7 * 24 * 60 * 60 * 1000;

  static final Map<String, _Entry> _mem = {};

  // 앱 시작 시 init()으로 미리 받아둠 → getSync()에서 동기 조회 가능
  static SharedPreferences? _prefs;

  static String _key(String url) => '$_prefix$url';

  static bool _expired(int ts) =>
      DateTime.now().millisecondsSinceEpoch - ts > _maxAgeMs;

  /// main()에서 AppPreferences.init() 직후 호출.
  /// SharedPreferences는 초기화 후 내부가 메모리 맵이므로
  /// 이후 getString()은 실질적으로 동기 처리됨.
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

  /// 동기 조회 — _mem → _prefs(SharedPreferences 인스턴스) 순서.
  /// 앱 재시작 후 오프라인 접근 시에도 즉시 캐시 반환 가능.
  static dynamic getSync(String url) {
    // 1차: 메모리
    final e = _mem[url];
    if (e != null) {
      if (_expired(e.ts)) {
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
      if (_expired(ts)) {
        prefs.remove(_key(url));
        return null;
      }
      // SharedPreferences 데이터를 메모리에 올려 다음 조회는 1차에서 처리
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
      if (_expired(ts)) {
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
