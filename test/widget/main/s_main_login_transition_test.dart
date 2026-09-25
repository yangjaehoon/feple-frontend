import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:feple/screen/main/tab/community_board/f_community_board.dart';
import 'package:feple/screen/main/tab/home/f_home.dart';
import 'package:feple/screen/main/tab/search/f_search.dart';
import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 's_main_test_fakes.dart';

/// 콜드스타트에서는 위젯 트리가 자동 로그인보다 **먼저** 빌드되므로
/// [MainScreen]과 앱바의 `initState`가 게스트 기준으로 돌아간다. 최상위
/// `Consumer`가 로그인 전후로 같은 `App` 위젯을 반환해 엘리먼트가 재사용되는
/// 탓에 `initState`는 다시 실행되지 않는다 — 그래서 로그인 전이를
/// [MainScreenState]가 직접 보정해야 한다. 이 파일이 그 보정을 고정한다.
///
/// `CustomThemeScope` + `Builder` 조합은 한 파일 안에서 두 번째 pumpWidget부터
/// 화면이 비어버려서, 여러 testWidgets를 담은 다른 파일들처럼
/// `CustomThemeHolder`에 고정 테마를 넘기는 방식을 쓴다
/// (`s_main_bottom_nav_inset_test.dart`의 주석 참고).
late MockNotificationCountable mockNotificationCountable;

Future<void> _pumpMainScreen(
  WidgetTester tester,
  UserProvider userProvider,
) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  // 기본 800x600에서는 탭 콘텐츠가 넘쳐 렌더 오버플로 예외가 난다.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(home: MainScreen()),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// 게스트가 직접 게시판 탭으로 옮긴 상태를 만든다.
Future<void> _switchToBoardTab(WidgetTester tester) async {
  tester
      .state<MainScreenState>(find.byType(MainScreen))
      .switchToTab(TabItem.communityBoard);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byType(CommunityBoardFragment), findsOneWidget);
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
  });

  setUp(() {
    // 알림 개수 조회 횟수를 테스트마다 따로 세야 해서 목을 새로 만든다.
    mockNotificationCountable = registerMainScreenTabMocks();
  });

  testWidgets('자동 로그인이 뒤늦게 끝나도 로그인 사용자의 시작 탭(홈)으로 옮겨간다',
      (tester) async {
    // 콜드스타트 재현 — 트리가 빌드되는 시점엔 아직 게스트다.
    final userProvider = FakeUserProvider();
    await _pumpMainScreen(tester, userProvider);
    expect(find.byType(SearchFragment), findsOneWidget);

    // 자동 로그인 완료.
    userProvider.setUserForTest(AppUser(id: 1, nickname: '테스터'));
    await tester.pump();

    expect(find.byType(HomeFragment), findsOneWidget,
        reason: '로그인 사용자는 게스트용 검색 탭이 아니라 홈 탭에서 시작해야 한다');
    expect(find.byType(SearchFragment), findsNothing);
  });

  testWidgets('이미 다른 탭으로 옮긴 뒤 로그인하면 보고 있던 탭을 유지한다',
      (tester) async {
    final userProvider = FakeUserProvider();
    await _pumpMainScreen(tester, userProvider);
    await _switchToBoardTab(tester);

    userProvider.setUserForTest(AppUser(id: 1, nickname: '테스터'));
    await tester.pump();

    expect(find.byType(CommunityBoardFragment), findsOneWidget,
        reason: '사용자가 직접 고른 탭을 로그인 전이가 빼앗으면 안 된다');
    expect(find.byType(HomeFragment), findsNothing);
  });

  // 검색 바로가기는 게스트 기본 탭과 같은 탭이라 방문 이력이 늘지 않는다 —
  // "직접 골랐는지"를 따로 기억하지 않으면 사용자가 누른 바로가기를 뒤늦게
  // 끝난 자동 로그인이 덮어쓴다.
  testWidgets('검색 바로가기로 들어오면 자동 로그인이 끝나도 검색 탭에 남는다',
      (tester) async {
    final userProvider = FakeUserProvider();
    await _pumpMainScreen(tester, userProvider);

    tester
        .state<MainScreenState>(find.byType(MainScreen))
        .switchToTab(TabItem.search);
    await tester.pump();

    userProvider.setUserForTest(AppUser(id: 1, nickname: '테스터'));
    await tester.pump();

    expect(find.byType(SearchFragment), findsOneWidget,
        reason: '사용자가 누른 바로가기를 로그인 전이가 덮어쓰면 안 된다');
    expect(find.byType(HomeFragment), findsNothing);
  });

  testWidgets('홈 탭에서 로그아웃하면 게스트용 시작 탭으로 내려온다', (tester) async {
    final userProvider = FakeUserProvider();
    await _pumpMainScreen(tester, userProvider);
    userProvider.setUserForTest(AppUser(id: 1, nickname: '테스터'));
    await tester.pump();
    expect(find.byType(HomeFragment), findsOneWidget);

    userProvider.setUserForTest(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 게스트에게 홈 탭은 로그인 유도 화면뿐이라 그대로 두면 갇힌다.
    expect(find.byType(SearchFragment), findsOneWidget);
    expect(find.byType(HomeFragment), findsNothing);
  });

  // 탭이 바뀌면 새로 뜨는 홈 앱바가 자기 initState에서 개수를 조회해버려
  // MainScreen의 보정이 없어도 통과한다. 탭이 그대로인 이 경로가 보정을
  // 실제로 검증하는 유일한 지점이다.
  testWidgets('탭이 그대로인 로그인 전이에서도 안 읽은 알림 개수를 조회한다',
      (tester) async {
    final userProvider = FakeUserProvider();
    await _pumpMainScreen(tester, userProvider);
    await _switchToBoardTab(tester);
    // 게스트에게 개수 조회는 401이라 애초에 생략된다.
    verifyNever(() => mockNotificationCountable.getUnreadCount());

    userProvider.setUserForTest(AppUser(id: 1, nickname: '테스터'));
    await tester.pump();

    // 이걸 빠뜨리면 알림함에 들어갔다 나오기 전까지 벨 배지와 앱 아이콘
    // 배지가 0으로 남는다.
    verify(() => mockNotificationCountable.getUnreadCount()).called(1);
  });
}
