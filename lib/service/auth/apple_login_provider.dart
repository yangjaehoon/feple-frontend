import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';
import 'firebase_id_token.dart';

const _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

/// Firebase가 Apple ID 토큰의 재생 공격을 막기 위해 요구하는 raw nonce 생성.
String _generateNonce([int length = 32]) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => _nonceCharset[random.nextInt(_nonceCharset.length)],
  ).join();
}

String _sha256OfString(String input) => sha256.convert(utf8.encode(input)).toString();

/// Apple Sign-In → Firebase credential 교환 흐름.
class AppleLoginProvider {
  AppleLoginProvider(this._tokenExchanger);

  final AuthTokenExchanger _tokenExchanger;

  Future<app.AppUser> login() async {
    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256OfString(rawNonce),
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    final idToken = await requireFirebaseIdToken(userCredential.user);

    // Apple은 최초 로그인 시에만 이름을 제공, 반환 사용자는 null
    final givenName = appleCredential.givenName;
    final familyName = appleCredential.familyName;
    final fullName = [givenName, familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return _tokenExchanger.exchangeFirebaseToken(
      idToken,
      nickname: fullName.isNotEmpty ? fullName : null,
    );
  }
}
