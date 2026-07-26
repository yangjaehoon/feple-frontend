import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/home/f_home.dart';
import 'package:feple/screen/main/tab/home/s_liked_festivals.dart';
import 'package:feple/screen/main/tab/home/w_boards_section_skeleton.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/cache_prefetch_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}
class MockFestivalCacheService extends Mock implements FestivalCacheService {}
class MockCachePrefetchService extends Mock implements CachePrefetchService {}
class MockNotificationCountable extends Mock implements NotificationCountable {}
class MockUserProvider extends Mock implements UserProvider {}

FollowedArtist _artist({int id = 1, String name = '아티스트'}) =>
    FollowedArtist(id: id, name: name);

FestivalModel _festival({int id = 1, String title = '축제'}) {
  final now = DateTime.now();
  return FestivalModel(
    id: id,
    title: title,
    description: '',
    location: '',
    startDate: now.toIso8601String(),
    endDate: now.add(const Duration(days: 5)).toIso8601String(),
    posterUrl: '',
  );
}

Future<void> _pump(WidgetTester tester, {int? userId = 1}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final userProvider = MockUserProvider();
  when(() => userProvider.currentUserId).thenReturn(userId);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: ChangeNotifierProvider<UserProvider>.value(
        value: userProvider,
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(home: HomeFragment()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  late MockUserService mockUserService;
  late MockFestivalCacheService mockCacheService;
  late MockCachePrefetchService mockPrefetchService;
  late MockNotificationCountable mockNotificationCountable;

  setUp(() {
    mockUserService = MockUserService();
    mockCacheService = MockFestivalCacheService();
    mockPrefetchService = MockCachePrefetchService();
    mockNotificationCountable = MockNotificationCountable();

    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    if (sl.isRegistered<FestivalCacheService>()) sl.unregister<FestivalCacheService>();
    if (sl.isRegistered<CachePrefetchService>()) sl.unregister<CachePrefetchService>();
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    if (sl.isRegistered<NotificationCountNotifier>()) sl.unregister<NotificationCountNotifier>();

    sl.registerSingleton<UserService>(mockUserService);
    sl.registerSingleton<FestivalCacheService>(mockCacheService);
    sl.registerSingleton<CachePrefetchService>(mockPrefetchService);
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
    sl.registerFactory<NotificationCountNotifier>(() => NotificationCountNotifier());

    when(() => mockCacheService.loadHomeFestivals(any())).thenAnswer((_) async => null);
    when(() => mockCacheService.loadHomeArtists(any())).thenAnswer((_) async => null);
    when(() => mockCacheService.saveHomeFestivals(any(), any())).thenAnswer((_) async {});
    when(() => mockCacheService.saveHomeArtists(any(), any())).thenAnswer((_) async {});
    when(() => mockPrefetchService.prefetchForFestivals(any())).thenAnswer((_) async {});
    when(() => mockNotificationCountable.getUnreadCount()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    if (sl.isRegistered<FestivalCacheService>()) sl.unregister<FestivalCacheService>();
    if (sl.isRegistered<CachePrefetchService>()) sl.unregister<CachePrefetchService>();
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    if (sl.isRegistered<NotificationCountNotifier>()) sl.unregister<NotificationCountNotifier>();
  });

  group('HomeFragment 렌더링', () {
    testWidgets('userId가 없으면 전체 화면 로딩 인디케이터를 보여준다', (tester) async {
      await _pump(tester, userId: null);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('데이터 로드가 완료되면 아티스트/축제 섹션을 보여준다', (tester) async {
      when(() => mockUserService.fetchFollowingArtists(1))
          .thenAnswer((_) async => [_artist(name: '아이유')]);
      when(() => mockUserService.fetchLikedFestivals(1))
          .thenAnswer((_) async => [_festival(title: '서울재즈')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('followed_artists'.tr()), findsOneWidget);
      expect(find.text('liked_festivals'.tr()), findsOneWidget);
      expect(find.text('아이유'), findsOneWidget);
      expect(find.text('서울재즈'), findsOneWidget);
    });

    testWidgets('로드 실패 시 각 섹션에 에러 상태를 보여준다', (tester) async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenThrow(Exception('오류'));
      when(() => mockUserService.fetchLikedFestivals(1)).thenThrow(Exception('오류'));

      await _pump(tester);
      await tester.pumpAndSettle();

      // 아티스트/축제/즐겨찾기 게시판 섹션이 각각 자체 ErrorState를 보여준다
      expect(find.byType(ErrorState), findsNWidgets(3));
    });

    testWidgets('로딩 중에는 게시판 섹션에 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<List<FollowedArtist>>();
      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) => completer.future);
      when(() => mockUserService.fetchLikedFestivals(1)).thenAnswer((_) async => []);

      await _pump(tester);

      expect(find.byType(BoardsSectionSkeleton), findsOneWidget);
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('HomeFragment 더보기 네비게이션', () {
    testWidgets('좋아요한 페스티벌이 있으면 더보기 버튼으로 LikedFestivalsScreen에 진입한다', (tester) async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) async => []);
      when(() => mockUserService.fetchLikedFestivals(1))
          .thenAnswer((_) async => [_festival(title: '서울재즈')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      // see_all 버튼은 아티스트(비어있으면 없음)/축제/즐겨찾기 게시판 섹션
      // 순서로 나타난다 — 축제가 유일하게 있는 상태이므로 첫 번째가 축제 섹션.
      await tester.tap(find.byTooltip('see_all'.tr()).first);
      await tester.pumpAndSettle();

      expect(find.byType(LikedFestivalsScreen), findsOneWidget);
    });
  });

  group('HomeFragment 재시도', () {
    testWidgets('에러 상태에서 재시도하면 정상적으로 데이터를 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('오류');
        return [_artist(name: '복구된아티스트')];
      });
      when(() => mockUserService.fetchLikedFestivals(1)).thenAnswer((_) async => []);

      await _pump(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ErrorState), findsNWidgets(3));

      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      expect(find.text('복구된아티스트'), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);
    });
  });
}
