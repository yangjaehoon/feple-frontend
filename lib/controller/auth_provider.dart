import 'package:flutter/foundation.dart';
import 'package:feple/injection.dart';
import '../auth/auth_api.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart' as app;

class AuthProvider extends ChangeNotifier {
  final _authApi = sl<AuthApi>();
  app.User? user;
  bool isLoading = false;

  Future<void> loginWithKakaoAccessToken(String kakaoAccessToken) async {
    isLoading = true;
    notifyListeners();
    try {
      user = await _authApi.loginWithKakaoAccessToken(kakaoAccessToken);
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
