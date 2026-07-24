import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_text_scale_clamp.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feple/login/s_login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'auth/keys.dart';
import 'auth/token_store.dart';
import 'common/data/preference/app_preferences.dart';
import 'common/data/preference/prefs.dart';
import 'package:dio/dio.dart' show DioException;
import 'network/api_cache_store.dart';
import 'network/dio_client.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'common/theme/custom_theme_app.dart';
import 'screen/onboarding/s_onboarding.dart';

void main() async {
  final bindings = WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  setupDependencies();

  // 기본 ImageCache: 1000개 / 100MB — 고해상도 포스터가 많은 페스티벌 앱 특성상
  // 이미지 수 제한을 줄이고 바이트 예산을 명시해 OOM 위험 감소
  PaintingBinding.instance.imageCache.maximumSize = 150;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 * 1024 * 1024; // 60MB
  FlutterNativeSplash.preserve(widgetsBinding: bindings);

  // google-services.json이 Android에서 자동 초기화하므로 중복 방지
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await EasyLocalization.ensureInitialized();
  await AppPreferences.init();
  await ApiCacheStore.init();

  KakaoSdk.init(
    nativeAppKey: kakaoNativeAppKey,
    javaScriptAppKey: kakaoJsAppKey,
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

  void _onOnboardingComplete() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
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
    // connect(5s) + receive(12s) + 갱신 재시도(20s) + 여유 = 40s 상한
    // _plainDio 타임아웃 없음으로 인한 무한 대기 방지
    // 최소 500ms 표시: 로그인이 빨리 끝나도 브랜드 인상을 위해 대기
    try {
      await Future.wait([
        _doAutoLogin(userProvider).timeout(const Duration(seconds: 40)),
        Future.delayed(const Duration(milliseconds: 500)),
      ]);
    } on TimeoutException {
      log('Auto login timed out');
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _doAutoLogin(UserProvider userProvider) async {
    try {
      final token = await TokenStore.readAccessToken();
      if (token != null) {
        await userProvider.fetchUserFromToken(token);
        // 로그인 성공 시 홈 데이터를 미리 캐싱 (최대 2초 대기)
        // → HomeFragment 진입 시 스켈레톤 없이 즉시 표시
        final userId = userProvider.currentUserId;
        if (userId != null) {
          await _prefetchHomeData(userId).timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );
        }
      }
    } on DioException catch (e) {
      if (e.response == null) {
        // 오프라인 — 서버 미도달, 토큰 유효성 확인 불가 → 캐시 user 유지
        log('Auto login failed (offline): ${e.type}');
      } else {
        // 서버 도달했으나 오류(5xx 등) — 401/403/404는 fetchUserFromToken이 이미 정리
        // 5xx는 서버 오류이므로 토큰 유지, 이후 API 호출 시 DioClient가 401 처리
        log('Auto login failed (server ${e.response?.statusCode})');
      }
    } catch (e) {
      // 응답 파싱 실패 등 예상치 못한 오류 — 죽은 토큰 정리
      log('Auto login failed (unexpected): $e');
      try {
        await userProvider.logout().timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomThemeApp(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // App.navigatorKey는 FCM 딥링크·계정 정지 다이얼로그·언어 조회 등에서
            // 로그인/온보딩 화면에서도 쓰여야 해서 유일한 MaterialApp에 붙임 —
            // 예전엔 App 위젯(로그인+온보딩 완료 후에만 생성됨)이 별도 MaterialApp을
            // 또 만들어 그 안에 navigatorKey를 붙였던 탓에, 로그인/온보딩 중에는
            // 이 키가 null이라 딥링크·정지 다이얼로그가 조용히 무시됐음
            navigatorKey: App.navigatorKey,
            title: 'Feple',
            theme: context.themeType.themeData,
            builder: clampTextScaleBuilder,
            home: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                if (userProvider.user == null) {
                  return const LoginScreen();
                } else if (!Prefs.onboardingCompleted.get()) {
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

// 스플래시 중 홈 데이터를 FestivalCacheService에 저장
// HomeStateNotifier가 캐시 우선 표시 전략으로 즉시 렌더링할 수 있게 함
Future<void> _prefetchHomeData(int userId) async {
  try {
    final (artists, festivals) = await (
      sl<UserService>().fetchFollowingArtists(userId),
      sl<UserService>().fetchLikedFestivals(userId),
    ).wait;
    await Future.wait([
      sl<FestivalCacheService>().saveHomeArtists(userId, artists),
      sl<FestivalCacheService>().saveHomeFestivals(userId, festivals),
    ]);
    log('Home pre-fetch: ${artists.length} artists, ${festivals.length} festivals');
  } catch (e) {
    log('Home pre-fetch failed (ignored): $e');
  }
}
