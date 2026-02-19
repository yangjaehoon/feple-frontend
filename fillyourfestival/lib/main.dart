import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/common/cli_common.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/provider/FestivalPreviewProvider.dart';
import 'package:fast_app_base/provider/poster/poster_provider.dart';
import 'package:fast_app_base/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/login/login.dart';
import 'package:fast_app_base/controller/auth_provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'auth/get_api_key.dart';
import 'auth/token_store.dart';
import 'common/data/preference/app_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/*
// Future<void> _initializeNaverMap() async {
//   final naverMapApiKey = await getApiKey("naver_map_client_id");
//    await NaverMapSdk.instance.initialize(
//      clientId: naverMapApiKey,
//      onAuthFailed: (e) => log("네이버맵 인증오류 : $e", name: "onAuthFailed"),
//    );
// }
*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bindings = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: bindings);

  //await Firebase.initializeApp();
  //await _initializeNaverMap();
  await EasyLocalization.ensureInitialized();
  await AppPreferences.init();

  KakaoSdk.init(
    nativeAppKey: await getApiKey("kakao_native_app_key"),
    javaScriptAppKey: await getApiKey("kakao_javaScript_app_key"),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      fallbackLocale: const Locale('en'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          ChangeNotifierProvider<PosterProvider>(
              create: (context) => PosterProvider()),
          ChangeNotifierProvider<UserProvider>(
              create: (context) => UserProvider()),
          ChangeNotifierProvider(
            create: (_) => FestivalPreviewProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.blue),
      home: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.user == null) {
            _tryAutoLogin(context, userProvider);
            return LoginPage();
          } else {
            return const App();
          }
        },
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }

  Future<void> _tryAutoLogin(BuildContext context, UserProvider userProvider) async {
    try {
      final token = await TokenStore.readAccessToken();
      if (token != null) {
        await userProvider.fetchUserFromToken(token);
        if (userProvider.user != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const App()));
        }
      }
    } catch (e) {
      log('Auto login failed: $e');
    }
  }
}
