import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore._();
  // resetOnError: 재설치 후 Keystore 키 소실로 복호화 실패 시 데이터를 초기화하고 null 반환
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );
  static const _kAccessToken = 'accessToken';
  static const _kRefreshToken = 'refreshToken';

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
}
