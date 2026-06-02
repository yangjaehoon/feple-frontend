import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:feple/common/common.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/login/s_login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'auth/get_api_key.dart';
import 'auth/token_store.dart';
import 'common/data/preference/app_preferences.dart';
import 'common/data/preference/prefs.dart';
import 'package:dio/dio.dart' show DioException;
import 'network/dio_client.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'common/theme/custom_theme_app.dart';
import 'screen/onboarding/s_onboarding.dart';

void main() async {
  final bindings = WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
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

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(
              create: (_) => UserProvider(sl<UserService>())),
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
  bool _isBanDialogShowing = false;
  bool _onboardingCompleted = false;

  void _onOnboardingComplete() {
    setState(() => _onboardingCompleted = true);
  }

  @override
  void initState() {
    super.initState();
    _onboardingCompleted = Prefs.onboardingCompleted.get();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      DioClient.onSessionExpired = () => userProvider.logout();
      DioClient.onUserBanned = () => _showBanDialog(userProvider);
      _tryAutoLogin(userProvider);
    });
  }

  Future<void> _showBanDialog(UserProvider userProvider) async {
    if (_isBanDialogShowing) return;
    _isBanDialogShowing = true;
    try {
      final ctx = App.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await showDialog<void>(
          context: ctx,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: Text('account_banned_title'.tr()),
            content: Text('account_banned_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text('confirm'.tr()),
              ),
            ],
          ),
        );
      }
    } finally {
      _isBanDialogShowing = false;
      if (userProvider.user != null) {
        await userProvider.logout();
      }
    }
  }

  Future<void> _tryAutoLogin(UserProvider userProvider) async {
    try {
      final token = await TokenStore.readAccessToken();
      if (token != null) {
        await userProvider.fetchUserFromToken(token);
      }
    } on DioException catch (e) {
      // 연결 오류(오프라인)는 캐시된 user 유지 — 나머지(4xx 등)는 fetchUserFromToken이 정리
      log('Auto login failed (network): ${e.type}');
    } catch (e) {
      // 예상치 못한 오류(응답 파싱 실패 등) — 죽은 토큰 정리
      log('Auto login failed (unexpected): $e');
      await userProvider.logout();
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
                } else if (!_onboardingCompleted) {
                  return OnboardingScreen(onComplete: _onOnboardingComplete);
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
