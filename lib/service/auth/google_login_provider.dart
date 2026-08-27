import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';
import 'firebase_id_token.dart';

/// Google Sign-In → Firebase credential 교환 흐름.
class GoogleLoginProvider {
  GoogleLoginProvider(this._tokenExchanger);

  final AuthTokenExchanger _tokenExchanger;

  bool _initialized = false;
  Future<void>? _initializing;

  // GoogleSignIn.instance.initialize()는 앱 생명주기 동안 정확히 한 번만 호출돼야 함.
  // 버튼 연타 등으로 동시에 호출되면 in-flight Future를 공유해 중복 실행을 막는다.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initializing ??= _initialize();
    await _initializing;
  }

  Future<void> _initialize() async {
    try {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    } finally {
      _initializing = null;
    }
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
    final firebaseIdToken = await requireFirebaseIdToken(userCredential.user);

    return _tokenExchanger.exchangeFirebaseToken(
      firebaseIdToken,
      nickname: account.displayName,
    );
  }
}
