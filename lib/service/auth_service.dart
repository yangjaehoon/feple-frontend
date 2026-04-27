import 'package:dio/dio.dart';
import 'package:feple/network/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../auth/token_store.dart';
import '../model/user_model.dart' as app;

/// 인증 관련 비즈니스 로직을 UI에서 분리한 서비스 클래스.
/// login.dart / signup.dart에서 공통으로 사용합니다.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // ── 이메일 로그인 ──

  Future<app.User> loginWithEmail(String email, String password) async {
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user!;

    // 이메일 인증 확인
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      throw EmailNotVerifiedException();
    }

    final idToken = await user.getIdToken();
    return _exchangeFirebaseToken(idToken!);
  }

  // ── 이메일 회원가입 (인증 이메일 발송만, 로그인하지 않음) ──

  Future<void> registerWithEmail(
      String email, String password, String nickname) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    try {
      // 닉네임을 Firebase displayName에 저장 (이메일 인증 후 첫 로그인 시 백엔드에서 사용)
      await credential.user!.updateDisplayName(nickname);
      await credential.user!.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // 실패 시 Firebase 계정 롤백
      try {
        await credential.user?.delete();
      } catch (e) {
        debugPrint('[Auth] 계정 롤백 실패: $e');
      }
      rethrow;
    }
  }

  // ── 카카오 로그인 ──

  Future<app.User> loginWithKakao() async {
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (e) {
        // 사용자가 직접 취소한 경우 웹 로그인으로 넘어가지 않음
        if (e.code == 'CANCELED') rethrow;
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }
    return _exchangeKakaoToken(token.accessToken);
  }

  // ── 비밀번호 재설정 ──

  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // ── Firebase 에러 메시지 변환 ──

  String firebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_err_invalid_credential'.tr();
      case 'too-many-requests':
        return 'auth_err_too_many_requests'.tr();
      case 'user-disabled':
        return 'auth_err_account_disabled'.tr();
      case 'email-already-in-use':
        return 'auth_err_email_in_use'.tr();
      case 'weak-password':
        return 'auth_err_weak_password'.tr();
      case 'invalid-email':
        return 'auth_err_invalid_email_format'.tr();
      case 'unknown':
        return 'auth_err_network_error'.tr();
      default:
        return 'auth_err_auth_failed_with_code'.tr(args: [code]);
    }
  }

  // ── 내부: Firebase ID 토큰 → 앱 JWT 교환 ──

  Future<app.User> _exchangeFirebaseToken(String idToken,
      {String? nickname}) async {
    final body = <String, dynamic>{'idToken': idToken};
    if (nickname != null) body['nickname'] = nickname;

    try {
      final response = await DioClient.dio.post(
        '/auth/firebase',
        data: body,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('auth_err_auth_failed'.tr());
      return _saveTokensAndParseUser(data);
    } on DioException catch (e) {
      final respBody = e.response?.data;
      if (respBody is Map<String, dynamic>) {
        throw Exception(respBody['message'] ?? 'auth_err_auth_failed'.tr());
      }
      throw Exception('auth_err_auth_failed'.tr());
    }
  }

  // ── 내부: 카카오 액세스 토큰 → 앱 JWT 교환 ──

  Future<app.User> _exchangeKakaoToken(String accessToken) async {
    try {
      final response = await DioClient.dio.post(
        '/auth/kakao',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('auth_err_auth_failed'.tr());
      return _saveTokensAndParseUser(data);
    } on DioException catch (e) {
      throw Exception(
          'Spring 서버 로그인 실패: [${e.type.name}] ${e.response?.statusCode ?? 'no response'}');
    }
  }

  // ── 내부: 토큰 저장 + User 파싱 ──

  Future<app.User> _saveTokensAndParseUser(Map<String, dynamic> json) async {
    await TokenStore.saveAccessToken(json['accessToken'] as String);
    final refreshToken = json['refreshToken'] as String?;
    if (refreshToken != null) await TokenStore.saveRefreshToken(refreshToken);

    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) throw Exception('auth_err_auth_failed'.tr());
    return app.User.fromJson(userJson);
  }
}

/// 이메일 인증이 완료되지 않은 경우 발생하는 예외
class EmailNotVerifiedException implements Exception {
  @override
  String toString() => 'EmailNotVerifiedException';
}
