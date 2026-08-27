import 'dart:convert';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/model/withdrawal_reason.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart';
import 'package:dio/dio.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService;

  AppUser? _user;
  bool _isLoggingOut = false;
  AppUser? get user => _user;
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
    final String? token;
    try {
      token = await TokenStore.readAccessToken();
    } catch (e) {
      // 재설치 후 Keystore 키 소실 등 복구 불가 오류 — 보안 스토리지 전체 초기화
      debugPrint('[UserProvider] 보안 스토리지 복구 불가 오류, 초기화');
      try {
        await TokenStore.clear();
        await TokenStore.deleteUserJson();
      } catch (_) {}
      return;
    }
    if (token == null) {
      await TokenStore.deleteUserJson();
      return;
    }

    try {
      final jsonString = await TokenStore.readUserJson();
      if (jsonString == null) return;
      final data = jsonDecode(jsonString);
      final cached = AppUser.fromJson(data);
      // JWT sub와 캐시 userId 불일치 → 다른 계정의 캐시 데이터 폐기
      final jwtUserId = TokenStore.parseJwtSub(token);
      if (jwtUserId != null && jwtUserId != cached.id) {
        await TokenStore.deleteUserJson();
        return;
      }
      _user = cached;
      notifyListeners();
    } catch (e) {
      // 캐시된 유저 JSON 스키마 불일치 등 파싱 실패 — 캐시만 버리고 유효한
      // 토큰은 보존한다(파싱 실패로 불필요한 강제 로그아웃이 발생하지 않도록)
      debugPrint('[UserProvider] 캐시된 유저 정보 파싱 실패, 캐시만 삭제: $e');
      try {
        await TokenStore.deleteUserJson();
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      // 각 정리 단계가 실패해도 나머지 단계는 계속 진행 — 하나라도 예외가
      // 전파되면 _user가 초기화되지 않아 로그아웃이 로컬 화면에 반영되지 않음
      // 리프레시 토큰 취소/FCM 정리/signOut은 서로 의존관계 없는 네트워크 호출이라
      // 병렬로 실행 — 순차 실행 시 지연이 합산되어 로그아웃 버튼을 눌러도
      // 수 초간 반응 없는 것처럼 느껴짐. 단, 토큰 삭제는 리프레시 토큰 취소가
      // TokenStore를 읽어야 하므로 그 이후에 실행해야 함
      await Future.wait([
        _runCleanupStep('리프레시 토큰 취소', () async {
          final refreshToken = await TokenStore.readRefreshToken();
          if (refreshToken != null) {
            await AuthService.instance.revokeRefreshToken(refreshToken);
          }
        }),
        _runCleanupStep('FCM 정리', () => FcmService.instance.stop()),
        _runCleanupStep('signOut', () => AuthService.instance.signOut()),
      ]);
      await Future.wait([
        _runCleanupStep('토큰 삭제', TokenStore.clear),
        _runCleanupStep('유저 캐시 삭제', TokenStore.deleteUserJson),
        _runCleanupStep('onboarding 초기화', () => Prefs.onboardingCompleted.set(false)),
      ]);
      _user = null;
      notifyListeners();
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> _runCleanupStep(String label, Future<void> Function() step) async {
    try {
      await step();
    } catch (e) {
      debugPrint('[UserProvider] $label 실패: $e');
    }
  }

  Future<void> deleteAccount(WithdrawalReason reason, {String? detail}) async {
    final id = _user?.id;
    if (id == null) return;
    await _userService.deleteUser(id, reason, detail: detail);
    await logout();
  }

  Future<void> setUser(AppUser me) async {
    _user = me;
    notifyListeners();
    await TokenStore.saveUserJson(jsonEncode(me.toJson()));
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
