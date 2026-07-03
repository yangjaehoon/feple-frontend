// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:feple/app.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/language/language.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_app.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/material.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}

class MockUserService extends Mock implements UserService {}

class MockNotificationCountable extends Mock implements NotificationCountable {}

void main() {
  late MockFestivalService mockFestivalService;
  late MockUserService mockUserService;
  late MockNotificationCountable mockNotificationCountable;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
    await EasyLocalization.ensureInitialized();
    await AppPreferences.init();
    setupDependencies();

    // Replace FestivalService with mock to prevent hanging HTTP calls (avoids
    // SkeletonBox shimmer animation that prevents pumpAndSettle from settling).
    mockFestivalService = MockFestivalService();
    when(() => mockFestivalService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
          genres: any(named: 'genres'),
          regions: any(named: 'regions'),
          ageRestrictions: any(named: 'ageRestrictions'),
        )).thenAnswer((_) async => <FestivalPreview>[]);
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);

    // Replace UserService with mock so HomeStateNotifier.init() doesn't make
    // real HTTP calls (avoids CircularProgressIndicator from userId != null path).
    mockUserService = MockUserService();
    when(() => mockUserService.fetchFollowingArtists(any()))
        .thenAnswer((_) async => <FollowedArtist>[]);
    when(() => mockUserService.fetchLikedFestivals(any()))
        .thenAnswer((_) async => <FestivalModel>[]);
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    sl.registerSingleton<UserService>(mockUserService);

    // Replace NotificationCountable with mock so FepleAppBar.initState() doesn't
    // trigger a real HTTP call (Dio's 10s connect timeout races with pumpAndSettle).
    mockNotificationCountable = MockNotificationCountable();
    when(() => mockNotificationCountable.getUnreadCount())
        .thenAnswer((_) async => 0);
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
  });

  testWidgets('앱 실행 및 기본 세팅 확인', (WidgetTester tester) async {
    await pumpApp(tester);
    // Avoid pumpAndSettle: CircularProgressIndicator in HomeFragment (userId==null)
    // is an infinite animation that would cause pumpAndSettle to time out.
    // With mocked services there are no pending Dio timers, so pump() is safe.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Localizations test
    expect(currentLanguage, Language.korean); //startLocale: const Locale('ko') 이 설정되어 있으므로 한국어로 시작

    // 2. Custom Theme test
    expect(App.navigatorKey.currentContext!.themeType, CustomTheme.light);
    App.navigatorKey.currentContext!.changeTheme(CustomTheme.dark);
    await tester.pump();
    expect(App.navigatorKey.currentContext!.themeType, CustomTheme.dark);
  });
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider(sl<UserService>())),
          ChangeNotifierProvider(
              create: (_) => FestivalPreviewProvider(sl<FestivalService>())),
        ],
        child: const CustomThemeApp(child: App()),
      )));
}
