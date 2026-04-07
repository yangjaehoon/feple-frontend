import 'package:dio/dio.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final idToken = await credential.user!.getIdToken();
    return _exchangeFirebaseToken(idToken!);
  }

  // ── 이메일 회원가입 ──

  Future<app.User> registerWithEmail(
      String email, String password, String nickname) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    try {
      final idToken = await credential.user!.getIdToken();
      return await _exchangeFirebaseToken(idToken!, nickname: nickname);
    } catch (e) {
      // 백엔드 등록 실패 시 Firebase 계정 롤백
      try {
        await credential.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  // ── 카카오 로그인 ──

  Future<app.User> loginWithKakao() async {
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
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
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'too-many-requests':
        return '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'unknown':
        return '네트워크 오류가 발생했습니다. 인터넷 연결을 확인하고 다시 시도해주세요.';
      default:
        return '인증에 실패했습니다. ($code)';
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
      return _saveTokensAndParseUser(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final respBody = e.response?.data;
      if (respBody is Map<String, dynamic>) {
        throw Exception(respBody['message'] ?? '인증에 실패했습니다.');
      }
      throw Exception('인증에 실패했습니다.');
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
      return _saveTokensAndParseUser(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          'Spring 서버 로그인 실패: ${e.response?.statusCode} ${e.response?.data}');
    }
  }

  // ── 내부: 토큰 저장 + User 파싱 ──

  Future<app.User> _saveTokensAndParseUser(Map<String, dynamic> json) async {
    await TokenStore.saveAccessToken(json['accessToken'] as String);
    final refreshToken = json['refreshToken'] as String?;
    if (refreshToken != null) await TokenStore.saveRefreshToken(refreshToken);

    return app.User.fromJson(json['user'] as Map<String, dynamic>);
  }
}
