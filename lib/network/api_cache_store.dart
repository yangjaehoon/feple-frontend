import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// GET 응답을 SharedPreferences에 직렬화해 보관하는 단순 캐시.
/// 오프라인 시 DioClient 인터셉터에서 꺼내 쓴다.
class ApiCacheStore {
  static const _prefix = 'api_cache_';
  // 7일이 지난 캐시는 만료로 간주
  static const int _maxAgeMs = 7 * 24 * 60 * 60 * 1000;

  static String _key(String url) => '$_prefix$url';

  static Future<void> put(String url, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode({
        'data': data,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(_key(url), encoded);
    } catch (_) {}
  }

  static Future<dynamic> get(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(url));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ts = map['ts'] as int;
      if (DateTime.now().millisecondsSinceEpoch - ts > _maxAgeMs) {
        await prefs.remove(_key(url));
        return null;
      }
      return map['data'];
    } catch (_) {
      return null;
    }
  }
}
