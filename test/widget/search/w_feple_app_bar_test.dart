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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationCountable extends Mock implements NotificationCountable {}

class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockNotificationCountable mockCountable;
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
    testWidgets('로그인 상태: 검색 + 알림 아이콘을 보여주고 로그인 버튼은 없다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester, loggedIn: true);
      await tester.pump();

      expect(find.text('아티스트'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'login'.tr()), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('비로그인 게스트: 알림 아이콘 자리에 로그인 버튼을 보여주고 개수 조회는 하지 않는다', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsNothing);
      expect(find.widgetWithText(TextButton, 'login'.tr()), findsOneWidget);
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

  group('FepleAppBar 로그인 버튼', () {
    // 비로그인 게스트는 어느 탭에 있든 상단바에서 바로 로그인할 수 있어야 한다.
    // (문의·약관·개인정보처리방침은 게스트 마이페이지로 이동)
    testWidgets('비로그인이면 pill 형태의 로그인 버튼을 보여준다', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.widgetWithText(TextButton, 'login'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.headset_mic_rounded), findsNothing);
    });

    testWidgets('로그인 상태면 로그인 버튼 대신 알림 아이콘을 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester, loggedIn: true);
      await tester.pump();

      expect(find.widgetWithText(TextButton, 'login'.tr()), findsNothing);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    });
  });

  // 검색/알림 아이콘 탭 시 이동하는 UnifiedSearchScreen/NotificationScreen은
  // 다수의 sl<> 의존성이 필요한 무거운 화면이라 이 테스트에서는 다루지 않는다
  // (기존 컨벤션) — 각 화면 전용 테스트에서 다룰 것
}
