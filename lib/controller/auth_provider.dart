import 'package:flutter/foundation.dart';
import '../auth/auth_api.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart' as app;

class AuthProvider extends ChangeNotifier {
  app.User? user;
  bool isLoading = false;

  // Future<void> loadFromStorage() async {
  //   final jwt = await TokenStore.readAccessToken();
  //   if (jwt == null) return;
  //
  //   user = await UserApi().me();
  //   notifyListeners();
  // }

  Future<void> loginWithKakaoAccessToken(String kakaoAccessToken) async {
    isLoading = true;
    notifyListeners();
    try {
      final u = await AuthApi().loginWithKakaoAccessToken(kakaoAccessToken);
      user = u;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await TokenStore.clear();
    user = null;
    notifyListeners();
  }
}
