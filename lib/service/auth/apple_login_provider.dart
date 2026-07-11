import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';

/// Apple Sign-In → Firebase credential 교환 흐름.
class AppleLoginProvider {
  AppleLoginProvider(this._tokenExchanger);

  final AuthTokenExchanger _tokenExchanger;

  Future<app.AppUser> login() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    final idToken = await userCredential.user!.getIdToken();

    // Apple은 최초 로그인 시에만 이름을 제공, 반환 사용자는 null
    final givenName = appleCredential.givenName;
    final familyName = appleCredential.familyName;
    final fullName = [givenName, familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return _tokenExchanger.exchangeFirebaseToken(
      idToken!,
      nickname: fullName.isNotEmpty ? fullName : null,
    );
  }
}
