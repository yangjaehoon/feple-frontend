import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationCountable extends Mock implements NotificationCountable {}

void main() {
  late MockNotificationCountable mockCountable;

  setUp(() {
    mockCountable = MockNotificationCountable();
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
    List<Widget> extraTrailingActions = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        startLocale: const Locale('ko'),
        fallbackLocale: const Locale('ko'),
        path: 'assets/translations',
        useOnlyLangCode: true,
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
    );
    await tester.pump();
  }

  group('FepleAppBar 렌더링', () {
    testWidgets('타이틀과 검색/알림 아이콘을 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester);
      await tester.pump();

      expect(find.text('아티스트'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
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

  group('FepleAppBar 알림 배지', () {
    testWidgets('읽지 않은 알림이 없으면 배지를 보여주지 않는다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 0);

      await pump(tester);
      await tester.pump();

      expect(find.text('0'), findsNothing);
    });

    testWidgets('읽지 않은 알림이 있으면 개수를 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 3);

      await pump(tester);
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('99개를 초과하면 99+로 보여준다', (tester) async {
      when(() => mockCountable.getUnreadCount()).thenAnswer((_) async => 150);

      await pump(tester);
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    });
  });

  // 검색/알림 아이콘 탭 시 이동하는 UnifiedSearchScreen/NotificationScreen은
  // 다수의 sl<> 의존성이 필요한 무거운 화면이라 이 테스트에서는 다루지 않는다
  // (기존 컨벤션) — 각 화면 전용 테스트에서 다룰 것
}
