import 'package:feple/common/exception/auth_exchange_exception.dart';
import 'package:feple/common/exception/email_not_verified_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';
import 'firebase_id_token.dart';

/// Firebase 이메일/비밀번호 인증 관련 로그인·회원가입·인증메일 흐름.
class FirebaseEmailLoginProvider {
  FirebaseEmailLoginProvider(this._tokenExchanger);

  final AuthTokenExchanger _tokenExchanger;

  Future<app.AppUser> login(String email, String password) async {
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw AuthExchangeException('email sign-in returned no user');
    }

    // 이메일 인증 확인 — signOut 없이 세션 유지, VerifyEmailPage에서 처리
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      throw EmailNotVerifiedException();
    }

    // force: true — 이메일 인증 후 세션이 재사용될 때 캐시된 토큰의
    // email_verified 클레임이 false일 수 있으므로 항상 최신 토큰 요청
    final idToken = await requireFirebaseIdToken(user, forceRefresh: true);
    return _tokenExchanger.exchangeFirebaseToken(idToken);
  }

  Future<void> register(String email, String password, String nickname) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw AuthExchangeException('createUser returned no user');
    }
    try {
      // 닉네임을 Firebase displayName에 저장 (이메일 인증 후 첫 로그인 시 백엔드에서 사용)
      await firebaseUser.updateDisplayName(nickname);
    } catch (e) {
      await _rollbackFailedRegistration(firebaseUser, e);
      rethrow;
    }
    try {
      await firebaseUser.sendEmailVerification();
      // signOut 제거 — VerifyEmailPage에서 Firebase 세션 사용
    } catch (e) {
      // 계정은 지우지 않는다 — 네트워크 순단 등 일시적 실패로 계정을 지우면 같은 이메일로
      // 재시도할 때마다 같은 이유로 또 지워지는 루프에 빠질 수 있다. 다만 실패를 삼키면
      // 호출자(SignupScreen)가 성공으로 오인해 인증메일이 오지 않은 VerifyEmailScreen으로
      // 넘어가 60초 재전송 쿨다운에 갇히므로, 계정만 보존하고 실패는 그대로 알린다 —
      // 재시도 시 이미 존재하는 계정이라 실패하면 로그인 화면에서 재로그인하면
      // login()이 인증메일을 다시 보낸다.
      debugPrint('[Auth] 인증메일 발송 실패: $e');
      rethrow;
    }
  }

  Future<void> _rollbackFailedRegistration(User firebaseUser, Object error) async {
    debugPrint('[Auth] 회원가입 실패, 계정 롤백: $error');
    try {
      await firebaseUser.delete();
    } catch (deleteError) {
      debugPrint('[Auth] 계정 롤백 실패: $deleteError');
    }
    await FirebaseAuth.instance.signOut();
  }

  /// 현재 Firebase 세션이 [email]의 **미인증** 계정인지.
  ///
  /// [register]는 signOut하지 않으므로, 인증 화면에서 뒤로 나와도 세션이 그대로
  /// 남는다. 같은 이메일로 다시 가입을 시도해 `email-already-in-use`가 났을 때
  /// "내가 방금 만든 미인증 계정"인지 판별하는 데 쓴다.
  bool isUnverifiedSessionFor(String email) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.emailVerified) return false;
    final sessionEmail = user.email;
    if (sessionEmail == null) return false;
    return sessionEmail.toLowerCase() == email.trim().toLowerCase();
  }

  /// 이미 존재하는 내 미인증 계정으로 가입을 재시도한 경우의 복구.
  ///
  /// 이 경로에서는 [register]가 계정 생성 단계에서 `email-already-in-use`로 실패해
  /// **인증메일이 아직 나가지 않았고** displayName도 갱신되지 않았다. 닉네임을 바꿔
  /// 재시도했을 수 있으므로 displayName을 먼저 갱신한다 — 백엔드는 인증 후 첫 토큰
  /// 교환 때 이 값으로 User 행을 만든다.
  ///
  /// 인증메일 발송 실패는 [register]와 동일하게 그대로 전파한다. 삼키면 호출자가
  /// "메일을 보냈습니다"와 60초 재전송 쿨다운을 띄우는 화면으로 넘어가 버린다.
  Future<void> resumeUnverifiedSignup(String nickname) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw AuthExchangeException('no unverified session to resume');
    try {
      await user.updateDisplayName(nickname);
    } catch (e) {
      // 닉네임 갱신 실패는 인증 자체를 막지 않는다 — 기존 displayName으로 진행.
      debugPrint('[Auth] 재시도 중 닉네임 갱신 실패: $e');
    }
    await user.sendEmailVerification();
  }

  Future<void> resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await user.sendEmailVerification();
  }

  Future<void> cancelUnverifiedSignup() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      debugPrint('[Auth] 미인증 계정 삭제 실패: $e');
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<app.AppUser?> completeVerifiedLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed?.emailVerified != true) return null;
    // force: true로 최신 email_verified 클레임이 담긴 토큰 요청
    final idToken = await requireFirebaseIdToken(refreshed, forceRefresh: true);
    return _tokenExchanger.exchangeFirebaseToken(idToken);
  }

  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}
