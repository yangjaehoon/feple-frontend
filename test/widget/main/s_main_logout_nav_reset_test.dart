import 'dart:io';

import 'package:feple/app.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme_scope.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:feple/screen/main/tab/search/f_search.dart';
import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}

class MockNotificationCountable extends Mock implements NotificationCountable {}

/// 실제 UserProvider.logout()은 secure storage/FCM 등 플랫폼 채널을 기다려
/// 위젯 테스트에서 멈추므로, 로그인 상태만 토글하는 최소 페이크를 쓴다.
/// (MainScreen은 UserProvider 리스너로만 로그아웃을 감지한다.)
class _FakeUserProvider extends ChangeNotifier implements UserProvider {
  AppUser? _user;

  @override
  AppUser? get user => _user;

  @override
  int? get currentUserId => _user?.id;

  @override
  String? get currentProfileImageUrl => _user?.profileImageUrl;

  void setUserForTest(AppUser? value) {
    _user = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpApp(WidgetTester tester, UserProvider userProvider) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider(
            create: (_) => FestivalPreviewProvider(sl<FestivalService>()),
          ),
        ],
        child: CustomThemeScope(
          child: Builder(
            builder: (context) => MaterialApp(
              navigatorKey: App.navigatorKey,
              theme: context.themeType.themeData,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const App(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
    await EasyLocalization.ensureInitialized();
    await AppPreferences.init();
    setupDependencies();

    final mockFestivalService = MockFestivalService();
    when(() => mockFestivalService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
          genres: any(named: 'genres'),
          regions: any(named: 'regions'),
          ageRestrictions: any(named: 'ageRestrictions'),
        )).thenAnswer(
        (_) async => const FestivalPreviewPage(items: [], hasMore: false));
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);

    final mockNotificationCountable = MockNotificationCountable();
    when(() => mockNotificationCountable.getUnreadCount())
        .thenAnswer((_) async => 0);
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
  });

  testWidgets(
      '로그아웃하면 탭의 중첩 Navigator에 쌓여 있던 화면이 걷힌다',
      (tester) async {
    // 게스트로 시작 — 랜딩 탭은 비계정 콘텐츠인 검색 탭.
    final userProvider = _FakeUserProvider();
    await _pumpApp(tester, userProvider);

    expect(find.byType(SearchFragment), findsOneWidget);

    // 앱 안에서 로그인 → 설정 등 계정 화면을 현재 탭의 중첩 Navigator에 쌓는다.
    userProvider.setUserForTest(AppUser(id: 1, nickname: '테스터'));
    await tester.pump();

    final state = tester.state<MainScreenState>(find.byType(MainScreen));
    final landingIndex = TabItem.values.indexOf(TabItem.search);
    final tabNavigator = state.navigatorKeys[landingIndex].currentState!;
    unawaited(tabNavigator.push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('ACCOUNT_ONLY_ROUTE')),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ACCOUNT_ONLY_ROUTE'), findsOneWidget);
    expect(tabNavigator.canPop(), isTrue);

    // 로그아웃 — 최상위 라우팅이 같은 App 위젯을 유지해도 MainScreen이 각 탭의
    // 중첩 스택을 비워, 계정 화면이 RequireLoginGate 위에 남지 않게 한다.
    userProvider.setUserForTest(null);
    await tester.pump();

    expect(tabNavigator.canPop(), isFalse);
  });
}
