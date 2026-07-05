import 'dart:convert';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart';
import 'package:dio/dio.dart';

class UserProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );
  static const _kUserJson = 'userJson';

  final UserService _userService;

  User? _user;
  bool _isLoggingOut = false;
  User? get user => _user;
  int? get currentUserId => _user?.id;
  String? get currentProfileImageUrl => _user?.profileImageUrl;

  UserProvider(this._userService) {
    _loadFromSecureStorage();
  }

  Future<void> fetchUser(int userId) async {
    _user = await _userService.fetchUser(userId);
    notifyListeners();
  }

  Future<void> _loadFromSecureStorage() async {
    try {
      final token = await TokenStore.readAccessToken();
      if (token == null) {
        await _storage.delete(key: _kUserJson);
        return;
      }

      final jsonString = await _storage.read(key: _kUserJson);
      if (jsonString != null) {
        final data = jsonDecode(jsonString);
        final cached = User.fromJson(data);
        // JWT sub와 캐시 userId 불일치 → 다른 계정의 캐시 데이터 폐기
        final jwtUserId = _parseJwtSub(token);
        if (jwtUserId != null && jwtUserId != cached.id) {
          await _storage.delete(key: _kUserJson);
          return;
        }
        _user = cached;
        notifyListeners();
      }
    } catch (e) {
      // 재설치 후 Keystore 키 소실 등 복구 불가 오류 — 보안 스토리지 전체 초기화
      debugPrint('[UserProvider] 보안 스토리지 복구 불가 오류, 초기화');
      try {
        await TokenStore.clear();
        await _storage.delete(key: _kUserJson);
      } catch (_) {}
    }
  }

  static int? _parseJwtSub(String token) {
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

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      // 각 정리 단계가 실패해도 나머지 단계는 계속 진행 — 하나라도 예외가
      // 전파되면 _user가 초기화되지 않아 로그아웃이 로컬 화면에 반영되지 않음
      // 서버 리프레시 토큰 취소 — TokenStore.clear() 전에 호출해야 토큰을 읽을 수 있음
      try {
        final refreshToken = await TokenStore.readRefreshToken();
        if (refreshToken != null) {
          await AuthService.instance.revokeRefreshToken(refreshToken);
        }
      } catch (e) {
        debugPrint('[UserProvider] 리프레시 토큰 취소 실패: $e');
      }
      try {
        await FcmService.instance.stop();
      } catch (e) {
        debugPrint('[UserProvider] FCM 정리 실패: $e');
      }
      try {
        await AuthService.instance.signOut();
      } catch (e) {
        debugPrint('[UserProvider] signOut 실패: $e');
      }
      try {
        await TokenStore.clear();
      } catch (e) {
        debugPrint('[UserProvider] 토큰 삭제 실패: $e');
      }
      try {
        await _storage.delete(key: _kUserJson);
      } catch (e) {
        debugPrint('[UserProvider] 유저 캐시 삭제 실패: $e');
      }
      try {
        await Prefs.onboardingCompleted.set(false);
      } catch (e) {
        debugPrint('[UserProvider] onboarding 초기화 실패: $e');
      }
      _user = null;
      notifyListeners();
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> deleteAccount() async {
    final id = _user?.id;
    if (id == null) return;
    await _userService.deleteUser(id);
    await logout();
  }

  Future<void> setUser(User me) async {
    _user = me;
    notifyListeners();
    await _storage.write(
      key: _kUserJson,
      value: jsonEncode(me.toJson()),
    );
  }

  Future<void> fetchUserFromToken(String token) async {
    try {
      _user = await _userService.fetchUserFromToken(token);
      notifyListeners();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403 || status == 404) {
        // 401/403: 토큰 만료·무효, 404: 계정 삭제 → 죽은 토큰 정리
        _user = null;
        await TokenStore.clear();
        notifyListeners();
      }
      // 그 외(5xx, 네트워크 오류 등)는 오프라인 모드로 기존 user 유지
      rethrow;
    }
  }
}
