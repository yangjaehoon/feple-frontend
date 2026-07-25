import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';

/// Google Sign-In → Firebase credential 교환 흐름.
class GoogleLoginProvider {
  GoogleLoginProvider(this._tokenExchanger);

  final AuthTokenExchanger _tokenExchanger;

  bool _initialized = false;

  // GoogleSignIn.instance.initialize()는 앱 생명주기 동안 정확히 한 번만 호출돼야 함
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  Future<app.AppUser> login() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google ID token missing');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseIdToken = await userCredential.user!.getIdToken();

    return _tokenExchanger.exchangeFirebaseToken(
      firebaseIdToken!,
      nickname: account.displayName,
    );
  }
}
