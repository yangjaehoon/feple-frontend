import 'dart:developer';
import 'dart:ui';

import 'package:dio/dio.dart' show DioException;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';

import 'package:feple/app.dart';
import 'package:feple/auth/keys.dart';
import 'package:feple/auth/token_store.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/theme/custom_theme_scope.dart';
import 'package:feple/common/util/app_alert_dialog.dart';
import 'package:feple/common/util/deep_link_handler.dart';
import 'package:feple/common/util/update_prompt.dart';
import 'package:feple/common/widget/w_text_scale_clamp.dart';
import 'package:feple/injection.dart';
import 'package:feple/login/s_age_gate.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/provider/app_config_controller.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/onboarding/s_onboarding.dart';
import 'package:feple/screen/s_force_update.dart';
import 'package:feple/screen/s_maintenance.dart';
import 'package:feple/service/app_config_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/user_service.dart';

Future<void> main() async {
  final bindings = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: bindings);
  runApp(await _bootstrap() ? _appRoot() : const _BootstrapFailureApp());
}

/// 앱이 뜨기 전에 끝나야 하는 초기화. 성공하면 true.
///
/// 여기서 던지는 예외를 그냥 두면 `runApp`에 도달하지 못하고, Flutter가
/// 프레임을 한 번도 그리지 않아 **네이티브 런치 화면이 영원히 남는다** —
/// 에러도 재시도 수단도 없이 앱이 멈춘 것처럼 보인다. 그래서 전부 잡아서
/// 호출부가 안내 화면을 띄울 수 있게 한다.
Future<bool> _bootstrap() async {
  Future<void>? platformInit;
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setupDependencies();
    _configureImageCache();

    // 서로 의존관계 없는 초기화라 병렬로 실행 — 콜드스타트 시간을 합이 아닌
    // 가장 느린 것 하나의 시간으로 줄인다. Firebase를 기다리는 동안 같이 돈다.
    platformInit = Future.wait([
      EasyLocalization.ensureInitialized(),
      AppPreferences.init(),
      ApiCacheStore.init(),
      KakaoSdk.init(
        nativeAppKey: kakaoNativeAppKey,
        javaScriptAppKey: kakaoJsAppKey,
      ),
    ]);

    // 크래시 리포팅은 **가능한 한 이르게** 붙인다 — 시작 자체가 실패하는
    // 크래시야말로 가장 알아야 하는데, 초기화를 다 마친 뒤에 붙이면 그게
    // 정확히 사각지대가 된다. Firebase가 먼저 서야 하므로 그것만 앞세운다.
    // google-services.json이 Android에서 자동 초기화하므로 이미 초기화된
    // 경우 Firebase.initializeApp()은 생략.
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    // 텔레메트리 설정 실패가 앱 시작을 막아서는 안 된다 — 멀쩡한 앱을 두고
    // "시작하지 못했습니다"를 띄우게 된다.
    try {
      await _initCrashReporting();
    } catch (e) {
      log('Crash reporting setup failed (ignored): $e');
    }
    await platformInit;
    return true;
  } catch (e, stack) {
    // Firebase 초기화에서 던졌다면 platformInit은 await된 적이 없다. 그대로
    // 두면 미관측 비동기 에러가 되고, 핸들러가 이미 붙어 있으면 진짜 원인과
    // 무관한 크래시로 한 번 더 기록된다.
    unawaited(platformInit?.catchError((Object _) {}) ?? Future<void>.value());
    log('App bootstrap failed: $e');
    unawaited(_recordBootstrapError(e, stack));
    return false;
  }
}

/// 실패 안내 화면을 늦추지 않도록 기다리지 않는다 — 이 경로는 아직 네이티브
/// 런치 화면이 떠 있는 상태라 무엇도 오래 붙잡으면 안 된다. Firebase가 서기
/// 전에 실패했다면 기록할 곳 자체가 없으므로 그것까지 삼킨다.
Future<void> _recordBootstrapError(Object error, StackTrace stack) async {
  try {
    await FirebaseCrashlytics.instance
        .recordError(error, stack, reason: 'app bootstrap', fatal: true)
        .timeout(const Duration(seconds: 3));
  } catch (_) {}
}

Future<void> _initCrashReporting() async {
  // 디버그 빌드의 크래시/에러는 Crashlytics로 보내지 않음 — 개발 중 발생하는
  // 예외가 운영 대시보드를 오염시키는 것을 방지
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Widget _appRoot() {
  return EasyLocalization(
    supportedLocales: const [Locale('ko'), Locale('en')],
    fallbackLocale: const Locale('ko'),
    path: 'assets/translations',
    useOnlyLangCode: true,
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(sl<UserService>())),
        ChangeNotifierProvider<AppConfigController>(
            create: (_) => AppConfigController(sl<AppConfigService>())),
      ],
      child: const MyApp(),
    ),
  );
}

/// 초기화가 실패했을 때만 뜨는 최소 안내 화면. 예전에는 이 경우 네이티브 런치
/// 화면에 그대로 갇혔다.
///
/// 테마·Provider·번역 무엇에도 기대지 않는다 — 초기화가 실패했다는 건 그것들이
/// 준비되지 않았을 수 있다는 뜻이다. 그래서 문구도 `.tr()` 대신 플랫폼 로케일만
/// 보고 고른다(`EasyLocalization` 자체가 실패했으면 `.tr()`은 원본 키를 낸다).
///
/// **재시도 버튼은 일부러 두지 않았다.** [_bootstrap]은 한 번만 실행할 수 있다 —
/// `setupDependencies()`는 GetIt에 같은 타입을 다시 등록하면 던지고,
/// `AppPreferences._prefs`는 `late final`이라 두 번째 대입에서 던진다. 즉
/// 눌러도 항상 실패하는 버튼이 되므로, 앱을 완전히 종료 후 재실행하라고
/// 안내하는 편이 정직하다.
class _BootstrapFailureApp extends StatefulWidget {
  const _BootstrapFailureApp();

  @override
  State<_BootstrapFailureApp> createState() => _BootstrapFailureAppState();
}

class _BootstrapFailureAppState extends State<_BootstrapFailureApp> {
  @override
  void initState() {
    super.initState();
    // 정상 경로에서는 _tryAutoLogin의 finally가 지우지만 여기까지 왔다면
    // 그 코드는 실행되지 않는다 — 직접 지우지 않으면 스플래시가 남는다.
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = PlatformDispatcher.instance.locale.languageCode == 'ko';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFF9E9E9E)),
                const SizedBox(height: 16),
                Text(
                  isKorean
                      ? '앱을 시작하지 못했습니다.\n앱을 완전히 종료한 뒤 다시 실행해 주세요.'
                      : "Couldn't start the app.\n"
                          'Please close it completely and open it again.',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 15, color: Color(0xFF424242)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 콜드스타트 이후 루트에 올 화면의 종류. 판정([_MyAppState._rootDestination])과
/// 위젯 생성([_MyAppState._buildRootScreen])을 분리해, 화면 종류만 알면 되는
/// 호출부가 위젯을 만들지 않고도 판단할 수 있게 한다.
enum _RootDestination { maintenance, forceUpdate, ageGate, onboarding, app }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isBanDialogShowing = false;

  late final AppConfigController _appConfig;

  /// 온보딩 완료 여부는 `Prefs`(SharedPreferences)에 저장되고 [_rootDestination]이
  /// build 중에 읽는다 — 알려주는 notifier가 없어서 **이 setState가 유일한 갱신
  /// 수단**이다. 빈 setState라고 지우면 온보딩을 마쳐도 화면이 넘어가지 않는다.
  void _onOnboardingComplete() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Provider.of(listen: false)는 initState에서 안전 — post-frame으로 미루면
    // 첫 프레임 동안 401/ban 응답에 핸들러가 안 붙어 있는 창이 생긴다.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // 필드 이니셜라이저(late final)로 두면 "최초 읽기" 시점에 조회가 일어나
    // 나중에 dispose()에서 처음 건드리는 코드가 생기면 조상 조회가 실패한다.
    // initState에서 확실히 잡아둔다.
    _appConfig = Provider.of<AppConfigController>(context, listen: false);
    DioClient.onSessionExpired = () => userProvider.logout();
    DioClient.onUserBanned = () => _showBanDialog(userProvider);
    DioClient.onAgeVerificationRequired = () async =>
        userProvider.markAgeVerificationRequired();
    unawaited(_tryAutoLogin(userProvider));
    // 딥링크는 로그인/온보딩 상태와 무관하게 동작해야 하는데 App은 나이확인·
    // 온보딩·점검 게이트 화면에서는 트리에 없다 — 그래서 App이 아니라 유일한
    // MaterialApp을 갖는 이 위젯에서 초기화한다.
    // Navigator가 첫 프레임에 아직 마운트되지 않았을 수 있어 post-frame으로 미룬다.
    // (QuickActionHandler.register()는 '.tr()'을 쓰는데 이 시점엔 EasyLocalization
    // 번역 로딩이 아직 안 끝나 원본 키가 그대로 나가는 문제가 실측으로 확인돼
    // app.dart의 App.initState()로 옮겼다 — App은 MaterialApp의 home이라
    // localizationsDelegates가 로딩을 끝낸 뒤에야 빌드된다)
    WidgetsBinding.instance
        .addPostFrameCallback((_) => sl<DeepLinkHandler>().init());
  }

  @override
  void dispose() {
    sl<DeepLinkHandler>().dispose();
    super.dispose();
  }

  /// 온보딩 쪽([_onOnboardingComplete])과 달리 여기엔 setState가 필요 없다 —
  /// `markAgeVerified()`와 `fetchUser()`가 모두 `notifyListeners()`를 부르므로
  /// `home`의 `Consumer2`가 알아서 다시 빌드한다.
  Future<void> _onAgeVerified() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // 먼저 플래그를 내려 게이트를 확실히 벗어난 뒤, 최신 프로필로 재동기화한다.
    await userProvider.markAgeVerified();
    final id = userProvider.currentUserId;
    if (id != null) {
      try {
        await userProvider.fetchUser(id);
      } catch (e) {
        log('Age-verified user refetch failed: $e');
      }
    }
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
          builder: (dialogCtx) => buildAppAlertDialog(
            dialogCtx,
            title: 'account_banned_title'.tr(),
            content: 'account_banned_message'.tr(),
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

  /// 스플래시가 기다리는 것은 "이 사람이 누구인가"까지다.
  ///
  /// 토큰이 있으면 `userProvider.ready`(보안 스토리지의 캐시 로드) 시점에
  /// 이미 유저가 들어와 있다 — 네트워크 갱신은 그 프로필을 최신화할 뿐이라
  /// 붙잡아둘 이유가 없다. 예전에는 이 갱신까지 기다리느라 응답 없는
  /// 네트워크에서 최대 40초 동안 로고만 보였다.
  ///
  /// 앱 설정은 계속 기다린다 — 점검·강제 업데이트 판정을 진입 후로 미루면
  /// 앱을 보여줬다가 점검 화면으로 갈아치우게 된다(자체 6초 상한).
  Future<void> _tryAutoLogin(UserProvider userProvider) async {
    try {
      await Future.wait([
        _resolveIdentity(userProvider),
        _appConfig.load(),
        // 최소 500ms 표시: 로그인이 빨리 끝나도 브랜드 인상을 위해 대기
        Future.delayed(const Duration(milliseconds: 500)),
      ]);
    } finally {
      FlutterNativeSplash.remove();
      _maybePromptRecommendedUpdate();
    }
  }

  /// 캐시로 신원이 확정되면 갱신은 백그라운드로 넘기고 바로 반환한다.
  Future<void> _resolveIdentity(UserProvider userProvider) async {
    // 생성자의 캐시 로드가 먼저 끝나도록 기다린 뒤 네트워크로 갱신 —
    // 두 경로가 _user를 번갈아 쓰며 화면이 깜빡이는 경합 제거
    await userProvider.ready;
    final String? token;
    try {
      token = await TokenStore.readAccessToken();
    } catch (e) {
      log('Auto login skipped (token read failed): $e');
      return;
    }
    // 토큰이 없으면 게스트 — 갱신할 것도 기다릴 것도 없다.
    if (token == null) return;

    final refresh = _refreshIdentity(userProvider, token);
    // 토큰은 있는데 캐시가 비었다면(캐시 JSON 파싱 실패 등) 아직 이 사람이
    // 누구인지 모른다. 그대로 진입시키면 게스트 화면을 보여줬다가 뒤늦게
    // 나이확인·온보딩으로 갈아치우게 되므로 이때만 예전처럼 기다린다.
    if (userProvider.user == null) {
      await refresh;
      return;
    }
    unawaited(refresh);
  }

  /// 프로필 갱신과 홈 데이터 프리페치. 스플래시가 걷힌 뒤에도 이어질 수 있어
  /// 늦게 온 결과는 `UserProvider`의 인증 세대가 걸러준다.
  Future<void> _refreshIdentity(UserProvider userProvider, String token) async {
    // connect(5s) + receive(12s) + 갱신 재시도(20s) + 여유 = 40s 상한
    // _plainDio 타임아웃 없음으로 인한 무한 대기 방지
    final generation = userProvider.authGeneration;
    try {
      await userProvider
          .fetchUserFromToken(token)
          .timeout(const Duration(seconds: 40));
      // 로그인 성공 시 홈 데이터를 미리 캐싱 (최대 2초 대기)
      // → HomeFragment 진입 시 스켈레톤 없이 즉시 표시
      final userId = userProvider.currentUserId;
      if (userId != null) {
        await _prefetchHomeData(userId)
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      }
    } on TimeoutException {
      log('Auto login timed out');
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
      // 그 사이 사용자가 직접 로그인·로그아웃했다면 건드리면 안 된다.
      if (userProvider.authGeneration != generation) return;
      try {
        await userProvider.logout().timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
  }

  void _maybePromptRecommendedUpdate() {
    if (!mounted) return;
    final config = _appConfig.config;
    final currentVersion = _appConfig.currentVersion;
    if (config == null || currentVersion == null) return;
    // 점검·강제 업데이트 게이트나 나이 확인·온보딩 화면 위에 권장 업데이트
    // 다이얼로그가 겹치지 않도록, 실제 앱 화면일 때만 띄운다.
    final destination =
        _rootDestination(Provider.of<UserProvider>(context, listen: false));
    if (destination != _RootDestination.app) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = App.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      unawaited(maybePromptRecommendedUpdate(
        ctx,
        config: config,
        currentVersion: currentVersion,
      ));
    });
  }

  /// 콜드스타트 이후 루트에 무엇을 보여줄지 한곳에서 결정한다.
  /// [build]의 `home`과 [_maybePromptRecommendedUpdate]의 화면 판정이 갈라지지
  /// 않도록 공유한다 — 판정만 하고 위젯은 만들지 않으므로, 화면 종류만
  /// 알고 싶은 호출부가 화면 위젯을 통째로 만들었다 버리지 않아도 된다.
  _RootDestination _rootDestination(UserProvider userProvider) {
    // 점검 모드·강제 업데이트는 로그인/게스트 라우팅보다 우선한다.
    if (_appConfig.isUnderMaintenance) return _RootDestination.maintenance;
    if (_appConfig.requiresForceUpdate) return _RootDestination.forceUpdate;

    final user = userProvider.user;
    // 게스트 모드 — 페스티벌 목록·검색·커뮤니티 게시판 등 비계정 기능은
    // 로그인 없이 바로 접근 가능해야 함 (Apple 가이드라인 5.1.1(v)).
    if (user == null) return _RootDestination.app;
    // 만 14세 미만 커뮤니티 이용 차단 (App Store 심사 5.1.1) — 온보딩·홈
    // 진입 전에 생년월일을 1회 확인한다.
    if (user.ageVerificationRequired) return _RootDestination.ageGate;
    if (!Prefs.isOnboardingCompleted(user.id)) {
      return _RootDestination.onboarding;
    }
    return _RootDestination.app;
  }

  Widget _buildRootScreen(UserProvider userProvider) {
    final user = userProvider.user;
    return switch (_rootDestination(userProvider)) {
      _RootDestination.maintenance => MaintenanceScreen(
          message: _appConfig.maintenanceMessage,
          onRetry: _appConfig.reload,
        ),
      _RootDestination.forceUpdate => const ForceUpdateScreen(),
      _RootDestination.ageGate => AgeGateScreen(onVerified: _onAgeVerified),
      _RootDestination.onboarding when user != null => OnboardingScreen(
          userId: user.id,
          onComplete: _onOnboardingComplete,
        ),
      // onboarding은 user != null일 때만 나오지만(위 [_rootDestination]),
      // `!` 대신 게스트 화면으로 폴백해 둔다 — 나중에 판정 순서가 바뀌어도
      // 널 역참조로 죽지 않게. 분기를 빠뜨리면 컴파일이 막히도록 열거형 값을
      // 전부 명시한다.
      _RootDestination.onboarding ||
      _RootDestination.app =>
        App(noticeMessage: _appConfig.noticeMessage),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CustomThemeScope(
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
            // 점검·강제 업데이트 게이트와 게스트/나이확인/온보딩 라우팅은
            // [_rootDestination]에서 한곳에 모아 결정한다. 두 Provider를 모두
            // 구독해야 한다 — 설정이 뒤늦게 도착하면(점검 시작/해제) 게이트
            // 화면도 다시 판정해야 하기 때문.
            home: Consumer2<UserProvider, AppConfigController>(
              builder: (context, userProvider, _, _) =>
                  _buildRootScreen(userProvider),
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

/// 기본 ImageCache는 1000개 / 100MB — 고해상도 포스터가 많은 페스티벌 앱
/// 특성상 이미지 수 제한을 줄이고 바이트 예산을 명시해 OOM 위험을 낮춘다.
void _configureImageCache() {
  const maxImages = 150;
  const maxBytes = 60 * 1024 * 1024; // 60MB
  PaintingBinding.instance.imageCache
    ..maximumSize = maxImages
    ..maximumSizeBytes = maxBytes;
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
