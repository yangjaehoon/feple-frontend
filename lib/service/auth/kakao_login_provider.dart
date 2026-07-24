import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../model/user_model.dart' as app;
import 'auth_token_exchanger.dart';

/// 카카오 로그인(카카오톡 앱 → 실패 시 웹 로그인 폴백) 흐름.
class KakaoLoginProvider {
  KakaoLoginProvider(this._tokenExchanger);

  final AuthTokenExchanger _tokenExchanger;

  Future<app.AppUser> login() async {
    OAuthToken token;

    bool talkInstalled = false;
    try {
      talkInstalled = await isKakaoTalkInstalled();
    } catch (_) {
      debugPrint('[Auth] KakaoTalk 설치 확인 실패: 웹 로그인으로 폴백');
    }

    if (talkInstalled) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (e) {
        // 사용자가 직접 취소한 경우 웹 로그인으로 넘어가지 않음
        if (e.code == 'CANCELED') rethrow;
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }
    return _tokenExchanger.exchangeKakaoToken(token.accessToken);
  }
}
