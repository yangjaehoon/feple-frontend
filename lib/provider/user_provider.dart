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

  late final Future<void> _initialLoad;

  UserProvider(this._userService) {
    _initialLoad = _loadFromSecureStorage();
  }

  /// 생성자의 캐시 로드 완료를 기다리는 훅 — 자동 로그인(네트워크) 경로가
  /// 캐시 로드보다 먼저 시작해 결과를 덮어쓰는 경합을 없애기 위해 사용.
  Future<void> get ready => _initialLoad;

  /// user 설정 + 리스너 통지 + 오프라인 캐시(userJson) 갱신을 한 곳에서 처리.
  /// fetchUser/fetchUserFromToken/setUser가 모두 이 경로를 쓰도록 해
  /// "네트워크로 갱신했는데 오프라인 캐시는 옛날 정보" 상태를 방지한다.
  Future<void> _applyUser(AppUser me) async {
    _user = me;
    notifyListeners();
    try {
      await TokenStore.saveUserJson(jsonEncode(me.toJson()));
    } catch (e) {
      debugPrint('[UserProvider] 유저 캐시 저장 실패: $e');
    }
    // 로그인 성립 시점에 레거시 전역 온보딩 플래그를 유저 단위로 1회 이관
    // (자체 가드로 이미 이관됐으면 즉시 반환)
    await Prefs.migrateLegacyOnboarding(me.id);
  }

  Future<void> fetchUser(int userId) async {
    await _applyUser(await _userService.fetchUser(userId));
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
      // 네트워크 자동 로그인이 먼저 끝나 최신 user를 넣었으면 캐시본으로
      // 덮어쓰지 않는다
      if (_user != null) return;
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
      ]);
      // onboarding 완료 플래그는 유저 단위(onboardingCompleted_{id})라
      // 로그아웃 시 리셋하지 않는다 — 재로그인 시 온보딩 반복 방지
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

  Future<void> setUser(AppUser me) => _applyUser(me);

  /// 서버가 나이 확인 미완료(403 AGE_VERIFICATION_REQUIRED)를 응답했을 때 —
  /// 현재 유저에 플래그를 세워 루트 라우팅이 나이 확인 화면을 띄우게 한다.
  void markAgeVerificationRequired() {
    final me = _user;
    if (me != null && !me.ageVerificationRequired) {
      _user = me.copyWith(ageVerificationRequired: true);
      notifyListeners();
    }
  }

  /// 나이 확인을 통과했을 때 — 서버 재조회가 실패해도 게이트를 벗어나도록
  /// 플래그를 먼저 내린다. 캐시(userJson)에도 반영해 다음 콜드스타트에 되돌아가지 않게 한다.
  Future<void> markAgeVerified() async {
    final me = _user;
    if (me == null || !me.ageVerificationRequired) return;
    _user = me.copyWith(ageVerificationRequired: false);
    notifyListeners();
    try {
      await TokenStore.saveUserJson(jsonEncode(_user!.toJson()));
    } catch (e) {
      debugPrint('[UserProvider] 유저 캐시 저장 실패: $e');
    }
  }

  Future<void> fetchUserFromToken(String token) async {
    try {
      await _applyUser(await _userService.fetchUserFromToken(token));
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
