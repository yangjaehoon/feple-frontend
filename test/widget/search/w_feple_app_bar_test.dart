import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockNotificationCountable extends Mock implements NotificationCountable {}

class MockUserProvider extends Mock implements UserProvider {}

class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  bool returnSuccess = true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return returnSuccess;
  }
}

void main() {
  late MockNotificationCountable mockCountable;
  late FakeUrlLauncherPlatform fakeLauncher;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockCountable = MockNotificationCountable();
    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.user).thenReturn(null);
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    sl.registerSingleton<NotificationCountable>(mockCountable);
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
    sl.registerSingleton<NotificationCountNotifier>(NotificationCountNotifier());
    fakeLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  tearDown(() {
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    bool showBackButton = false,
    bool loggedIn = false,
    List<Widget> extraTrailingActions = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    when(() => mockUserProvider.user).thenReturn(
      loggedIn ? AppUser(id: 1, nickname: '테스터') : null,
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        startLocale: const Locale('ko'),
        fallbackLocale: const Locale('ko'),
        path: 'assets/translations',
        useOnlyLangCode: true,
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (_) {},
            child: MaterialApp(
              home: Scaffold(
                body: FepleAppBar(
                  '아티스트',
                  showBackButton: showBackButton,
                  extraTrailingActions: extraTrailingActions,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FepleAppBar 렌더링', () {
    testWidgets('로그인 상태: 검색 + 알림 아이콘을 보여주고 고객센터 아이콘은 없다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester, loggedIn: true);
      await tester.pump();

      expect(find.text('아티스트'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.byIcon(Icons.headset_mic_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('비로그인 게스트: 알림 아이콘 자리에 고객센터 아이콘을 보여주고 개수 조회는 하지 않는다', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsNothing);
      expect(find.byIcon(Icons.headset_mic_rounded), findsOneWidget);
      verifyNever(() => mockCountable.getUnreadCount());
    });

    testWidgets('showBackButton이 true면 뒤로가기 아이콘을 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester, showBackButton: true);
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('extraTrailingActions를 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester, extraTrailingActions: [const Icon(Icons.star)]);
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('FepleAppBar 알림 배지 (로그인 상태)', () {
    testWidgets('읽지 않은 알림이 없으면 배지를 보여주지 않는다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester, loggedIn: true);
      await tester.pump();

      expect(find.text('0'), findsNothing);
    });

    testWidgets('읽지 않은 알림이 있으면 개수를 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 3);

      await pump(tester, loggedIn: true);
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('99개를 초과하면 99+로 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 150);

      await pump(tester, loggedIn: true);
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('FepleAppBar 문의하기', () {
    // 로그인 화면·설정에 못 들어간 게스트도 이 아이콘으로 카카오톡 문의 채널에
    // 닿을 수 있어야 한다 (Apple 가이드라인 1.2). 비로그인이면 알림 아이콘 자리를
    // 고객센터 아이콘이 대신한다.
    testWidgets('비로그인이면 고객센터 아이콘을 보여주고 탭 시 카카오톡 링크를 연다', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.byIcon(Icons.headset_mic_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.headset_mic_rounded));
      await tester.pump();

      expect(fakeLauncher.launchedUrls, ['https://open.kakao.com/o/guLhbJki']);
    });

    testWidgets('로그인 상태면 고객센터 아이콘 대신 알림 아이콘을 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester, loggedIn: true);
      await tester.pump();

      expect(find.byIcon(Icons.headset_mic_rounded), findsNothing);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    });
  });

  // 검색/알림 아이콘 탭 시 이동하는 UnifiedSearchScreen/NotificationScreen은
  // 다수의 sl<> 의존성이 필요한 무거운 화면이라 이 테스트에서는 다루지 않는다
  // (기존 컨벤션) — 각 화면 전용 테스트에서 다룰 것
}
