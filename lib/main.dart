import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:feple/common/common.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/provider/like_notifier.dart';
import 'package:feple/provider/post_change_notifier.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:feple/login/login.dart';
import 'package:feple/controller/auth_provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'auth/get_api_key.dart';
import 'auth/token_store.dart';
import 'common/data/preference/app_preferences.dart';
import 'network/dio_client.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'common/theme/custom_theme_app.dart';

void main() async {
  final bindings = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: bindings);

  // google-services.json이 Android에서 자동 초기화하므로 중복 방지
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await EasyLocalization.ensureInitialized();
  await AppPreferences.init();

  KakaoSdk.init(
    nativeAppKey: await getApiKey("kakao_native_app_key"),
    javaScriptAppKey: await getApiKey("kakao_javaScript_app_key"),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          ChangeNotifierProvider<UserProvider>(
              create: (context) => UserProvider()),
          ChangeNotifierProvider(create: (_) => FestivalPreviewProvider()),
          ChangeNotifierProvider(create: (_) => LikeNotifier()),
          ChangeNotifierProvider(create: (_) => PostChangeNotifier()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      DioClient.onSessionExpired = () => userProvider.logout();
      _tryAutoLogin(userProvider);
    });
  }

  Future<void> _tryAutoLogin(UserProvider userProvider) async {
    try {
      final token = await TokenStore.readAccessToken();
      if (token != null) {
        await userProvider.fetchUserFromToken(token);
      }
    } catch (e) {
      log('Auto login failed: $e');
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomThemeApp(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            key: ValueKey(context.locale),
            debugShowCheckedModeBanner: false,
            theme: context.themeType.themeData,
            home: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                if (userProvider.user == null) {
                  return const LoginPage();
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
      ),
    );
  }
}
