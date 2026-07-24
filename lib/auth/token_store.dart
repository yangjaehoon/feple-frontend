import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore._();
  // resetOnError: 재설치 후 Keystore 키 소실로 복호화 실패 시 데이터를 초기화하고 null 반환
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );
  static const _kAccessToken = 'accessToken';
  static const _kRefreshToken = 'refreshToken';
  static const _kUserJson = 'userJson';

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _kAccessToken, value: token);
  }

  static Future<String?> readAccessToken() async {
    return _storage.read(key: _kAccessToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _kRefreshToken, value: token);
  }

  static Future<String?> readRefreshToken() async {
    return _storage.read(key: _kRefreshToken);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  // ── 캐시된 유저 JSON: 오프라인/콜드스타트 시 UserProvider가 즉시 표시할
  // 마지막으로 알려진 사용자 정보. 토큰과 별개 항목이지만 같은 보안 스토리지
  // 설정(resetOnError 등)을 공유해야 해서 TokenStore가 함께 관리 ──

  static Future<void> saveUserJson(String json) async {
    await _storage.write(key: _kUserJson, value: json);
  }

  static Future<String?> readUserJson() async {
    return _storage.read(key: _kUserJson);
  }

  static Future<void> deleteUserJson() async {
    await _storage.delete(key: _kUserJson);
  }

  /// JWT의 sub 클레임(유저 ID)만 필요할 때 서명 검증 없이 페이로드만 파싱.
  /// 서버 응답을 신뢰할 수 있는 컨텍스트(로컬 캐시 유효성 검증)에서만 사용.
  static int? parseJwtSub(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final sub = (decoded as Map<String, dynamic>)['sub'];
      return sub is String ? int.tryParse(sub) : (sub is int ? sub : null);
    } catch (_) {
      return null;
    }
  }
}
