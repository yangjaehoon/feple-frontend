import 'package:feple/common/exception/email_not_verified_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';

/// Firebase 이메일/비밀번호 인증 관련 로그인·회원가입·인증메일 흐름.
class FirebaseEmailLoginProvider {
  FirebaseEmailLoginProvider(this._tokenExchanger);

  final AuthTokenExchanger _tokenExchanger;

  Future<app.AppUser> login(String email, String password) async {
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user!;

    // 이메일 인증 확인 — signOut 없이 세션 유지, VerifyEmailPage에서 처리
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      throw EmailNotVerifiedException();
    }

    // force: true — 이메일 인증 후 세션이 재사용될 때 캐시된 토큰의
    // email_verified 클레임이 false일 수 있으므로 항상 최신 토큰 요청
    final idToken = await user.getIdToken(true);
    return _tokenExchanger.exchangeFirebaseToken(idToken!);
  }

  Future<void> register(String email, String password, String nickname) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final firebaseUser = credential.user!;
    try {
      // 닉네임을 Firebase displayName에 저장 (이메일 인증 후 첫 로그인 시 백엔드에서 사용)
      await firebaseUser.updateDisplayName(nickname);
      await firebaseUser.sendEmailVerification();
      // signOut 제거 — VerifyEmailPage에서 Firebase 세션 사용
    } catch (e) {
      // 실패 시 Firebase 계정 롤백
      try {
        await firebaseUser.delete();
      } catch (deleteError) {
        debugPrint('[Auth] 계정 롤백 실패: $deleteError');
      }
      await FirebaseAuth.instance.signOut();
      rethrow;
    }
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
    final idToken = await refreshed!.getIdToken(true);
    return _tokenExchanger.exchangeFirebaseToken(idToken!);
  }

  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}
