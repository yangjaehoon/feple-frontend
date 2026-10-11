import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';
import 'firebase_id_token.dart';

const _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

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
    final user = userCredential.user;
    final nameSaved =
        await _saveNameToFirebase(user, _appleFullName(appleCredential));
    // 이름을 방금 저장했다면 캐시된 토큰엔 name 클레임이 없으므로 새로 발급받는다.
    final idToken = await requireFirebaseIdToken(user, forceRefresh: nameSaved);
    return _tokenExchanger.exchangeFirebaseToken(idToken);
  }

  /// Apple은 이름을 **최초 로그인 때 한 번만** 주고, Firebase는 그 이름을 displayName에
  /// 자동으로 넣지 않는다. 서버는 ID 토큰의 name 클레임(= displayName)으로 닉네임을
  /// 만들므로, 여기서 저장하지 않으면 Apple 가입자는 전부 `User`+uid 닉네임을 받는다.
  /// Firebase에 저장해 두면 이번 서버 교환이 실패해도 다음 로그인에서 이름이 살아 있다.
  ///
  /// 저장했으면 true. 이름이 없거나(재로그인) 이미 있거나 저장에 실패하면 false —
  /// 실패해도 로그인은 막지 않는다(서버가 기본 닉네임으로 가입시킨다).
  Future<bool> _saveNameToFirebase(User? user, String fullName) async {
    if (user == null || fullName.isEmpty) return false;
    if (user.displayName?.isNotEmpty ?? false) return false;
    try {
      await user.updateDisplayName(fullName);
      return true;
    } catch (e) {
      debugPrint('[Auth] Apple 이름 저장 실패: $e');
      return false;
    }
  }
}

/// 한·중·일 문자가 섞인 이름 판정용 — 이 경우 성을 앞에, 공백 없이 붙인다.
final _cjkScript = RegExp(r'[\u3040-\u30FF\u3400-\u9FFF\uAC00-\uD7A3]');

/// Apple이 준 이름을 표시용 전체 이름으로 만든다. 이름이 없으면(재로그인) 빈 문자열.
/// 한국어 이름을 서양식(이름 성)으로 붙이면 '길동 홍'이 되고, 서버가 공백을 지워
/// '길동홍' 닉네임이 된다 — 한·중·일 이름은 성+이름으로 붙인다.
String _appleFullName(AuthorizationCredentialAppleID credential) {
  final given = credential.givenName?.trim() ?? '';
  final family = credential.familyName?.trim() ?? '';
  if (given.isEmpty || family.isEmpty) return given + family;
  return _cjkScript.hasMatch(given + family)
      ? '$family$given'
      : '$given $family';
}
