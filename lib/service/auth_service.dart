import 'package:feple/common/util/silent_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

export 'package:feple/common/exception/email_not_verified_exception.dart';

import '../model/user_model.dart' as app;
import 'auth/apple_login_provider.dart';
import 'auth/auth_token_exchanger.dart';
import 'auth/firebase_email_login_provider.dart';
import 'auth/firebase_error_translator.dart';
import 'auth/google_login_provider.dart';
import 'auth/kakao_login_provider.dart';

/// 인증 관련 비즈니스 로직을 UI에서 분리한 파사드.
/// 실제 제공자별 로직(이메일/카카오/Apple/Google)은 auth/ 하위 각 Provider가 담당하고,
/// 이 클래스는 login.dart / signup.dart 등에서 쓰는 단일 진입점 역할만 함.
class AuthService {
  factory AuthService._() => AuthService._withExchanger(AuthTokenExchanger());

  AuthService._withExchanger(AuthTokenExchanger tokenExchanger)
      : _tokenExchanger = tokenExchanger,
        _errorTranslator = FirebaseErrorTranslator(),
        _emailAuth = FirebaseEmailLoginProvider(tokenExchanger),
        _kakaoAuth = KakaoLoginProvider(tokenExchanger),
        _appleAuth = AppleLoginProvider(tokenExchanger),
        _googleAuth = GoogleLoginProvider(tokenExchanger);

  static final instance = AuthService._();

  final AuthTokenExchanger _tokenExchanger;
  final FirebaseErrorTranslator _errorTranslator;
  final FirebaseEmailLoginProvider _emailAuth;
  final KakaoLoginProvider _kakaoAuth;
  final AppleLoginProvider _appleAuth;
  final GoogleLoginProvider _googleAuth;

  // ── 이메일 로그인/회원가입 ──

  Future<app.AppUser> loginWithEmail(String email, String password) =>
      _emailAuth.login(email, password);

  Future<void> registerWithEmail(String email, String password, String nickname) =>
      _emailAuth.register(email, password, nickname);

  Future<void> resendVerificationEmail() => _emailAuth.resendVerificationEmail();

  Future<void> cancelUnverifiedSignup() => _emailAuth.cancelUnverifiedSignup();

  Future<app.AppUser?> completeVerifiedLogin() => _emailAuth.completeVerifiedLogin();

  Future<void> sendPasswordReset(String email) => _emailAuth.sendPasswordReset(email);

  // ── 카카오 / Apple / Google 로그인 ──

  Future<app.AppUser> loginWithKakao() => _kakaoAuth.login();

  Future<app.AppUser> loginWithApple() => _appleAuth.login();

  Future<app.AppUser> loginWithGoogle() => _googleAuth.login();

  // ── Firebase 에러 메시지 변환 ──

  String firebaseErrorMessage(String code) => _errorTranslator.translate(code);

  // ── 서버 리프레시 토큰 취소 ──

  Future<void> revokeRefreshToken(String refreshToken) =>
      _tokenExchanger.revokeRefreshToken(refreshToken);

  // ── 로그아웃: Firebase + Kakao 세션 정리 (두 제공자를 함께 정리해야 해서 파사드에 남김) ──

  Future<void> signOut() async {
    await runIgnoringErrors('[Auth] Firebase signOut 실패', FirebaseAuth.instance.signOut);
    // Kakao/Google 세션이 없는 경우(다른 방식으로 로그인)도 여기서 함께 무시됨
    await runIgnoringErrors('[Auth] Kakao logout 실패', UserApi.instance.logout);
    await runIgnoringErrors('[Auth] Google signOut 실패', GoogleSignIn.instance.signOut);
  }
}
