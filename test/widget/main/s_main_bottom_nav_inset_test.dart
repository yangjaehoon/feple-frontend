import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 's_main_test_fakes.dart';

/// [MainScreen]만 직접 펌프한다(전체 App() 부팅 경로를 타지 않음). 화면 크기·
/// 시스템 inset은 각 테스트 트리에 국한된 [MediaQuery] 오버라이드로 주입한다.
///
/// `CustomThemeHolder`를 고정 테마로 직접 쓰고 `MaterialApp`엔 홈만 넘긴다 —
/// `CustomThemeScope` + `Builder(context.themeType/localizationDelegates/
/// supportedLocales/locale)` 조합은 한 테스트 파일 안에서 두 번째 pumpWidget부터
/// 화면이 통째로 비어버리는 문제가 있어(원인 미상, easy_localization 관련 전역
/// 상태로 추정) 여러 testWidgets가 있는 다른 파일들이 쓰는 이 방식으로 맞췄다.
Future<void> _pumpMainScreen(
  WidgetTester tester, {
  required double screenWidth,
  required double systemBottomInset,
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
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => FakeUserProvider()),
          ChangeNotifierProvider(
            create: (_) => FestivalPreviewProvider(sl<FestivalService>()),
          ),
        ],
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(screenWidth, 2000),
                padding: EdgeInsets.only(bottom: systemBottomInset),
              ),
              child: const MainScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

double _renderedBottomInset(WidgetTester tester) {
  final padding = tester.widget<Padding>(
    find
        .ancestor(of: find.byType(NavigationBar), matching: find.byType(Padding))
        .first,
  );
  return (padding.padding as EdgeInsets).bottom;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
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

  group('하단 탭바 시스템 inset 처리', () {
    testWidgets('폰 폭에서는 큰 시스템 inset도 상한(bottomNavMaxInset)으로 clamp한다', (tester) async {
      await _pumpMainScreen(tester, screenWidth: 390, systemBottomInset: 60);

      expect(_renderedBottomInset(tester), AppDimens.bottomNavMaxInset);
    });

    testWidgets('태블릿급 폭(펼친 폴더블 등)에서는 큰 시스템 inset을 그대로 따른다 — '
        '대화면 태스크바에 탭바가 가려지는 것을 방지', (tester) async {
      await _pumpMainScreen(tester, screenWidth: 700, systemBottomInset: 60);

      expect(_renderedBottomInset(tester), 60.0);
    });

    testWidgets('태블릿급 폭이어도 시스템 inset이 원래 작으면 그대로 작게 유지된다',
        (tester) async {
      await _pumpMainScreen(tester, screenWidth: 700, systemBottomInset: 8);

      expect(_renderedBottomInset(tester), 8.0);
    });
  });
}
