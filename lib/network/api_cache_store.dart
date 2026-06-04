import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// GET 응답 캐시.
/// - 1차: 앱 메모리 (동기 조회 가능)
/// - 2차: SharedPreferences (앱 재시작 후에도 유지, 7일 TTL)
class ApiCacheStore {
  static const _prefix = 'api_cache_';
  static const int _maxAgeMs = 7 * 24 * 60 * 60 * 1000;

  // 인메모리 레이어 — 동기 조회용
  static final Map<String, _Entry> _mem = {};

  static String _key(String url) => '$_prefix$url';

  static bool _expired(int ts) =>
      DateTime.now().millisecondsSinceEpoch - ts > _maxAgeMs;

  static Future<void> put(String url, dynamic data) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    _mem[url] = _Entry(data, ts);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(url), jsonEncode({'data': data, 'ts': ts}));
    } catch (_) {}
  }

  /// 동기 조회 — 메모리에 있으면 즉시 반환, 없으면 null
  static dynamic getSync(String url) {
    final e = _mem[url];
    if (e == null) return null;
    if (_expired(e.ts)) { _mem.remove(url); return null; }
    return e.data;
  }

  /// 비동기 조회 — 메모리 → SharedPreferences 순서로 탐색
  static Future<dynamic> get(String url) async {
    final sync = getSync(url);
    if (sync != null) return sync;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(url));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ts = map['ts'] as int;
      if (_expired(ts)) { await prefs.remove(_key(url)); return null; }
      // SharedPreferences 데이터를 메모리에 올려 다음 조회는 동기 처리
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
