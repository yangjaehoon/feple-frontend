import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_rating_summary.dart';
import 'package:feple/model/my_certification_status.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artists.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_board.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_booth_map.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_poster.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_setlist.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_timetable.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}
class MockFestivalDetailService extends Mock implements FestivalDetailService {}
class MockFestivalService extends Mock implements FestivalService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}
class MockPostService extends Mock implements PostService {}
class MockNotificationCountable extends Mock implements NotificationCountable {}
class MockUserProvider extends Mock implements UserProvider {}

FestivalModel _poster({int id = 1, String title = '펜타포트'}) {
  return FestivalModel(
    id: id,
    title: title,
    description: '',
    location: '인천 송도달빛축제공원',
    startDate: '2026-08-01',
    endDate: '2026-08-03',
    posterUrl: '',
  );
}

void main() {
  late MockCertificationService mockCertService;
  late MockFestivalInteractionService mockFestivalInteractionService;
  late MockFestivalDetailService mockDetailService;
  late MockFestivalService mockFestivalDataService;
  late MockArtistFollowService mockFollowService;
  late MockPostService mockPostService;
  late MockNotificationCountable mockNotificationCountable;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() {
    mockCertService = MockCertificationService();
    mockFestivalInteractionService = MockFestivalInteractionService();
    mockDetailService = MockFestivalDetailService();
    mockFestivalDataService = MockFestivalService();
    mockFollowService = MockArtistFollowService();
    mockPostService = MockPostService();
    mockNotificationCountable = MockNotificationCountable();

    if (sl.isRegistered<CertificationService>()) sl.unregister<CertificationService>();
    if (sl.isRegistered<FestivalInteractionService>()) {
      sl.unregister<FestivalInteractionService>();
    }
    if (sl.isRegistered<FestivalDetailService>()) sl.unregister<FestivalDetailService>();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }

    sl.registerSingleton<CertificationService>(mockCertService);
    sl.registerSingleton<FestivalInteractionService>(mockFestivalInteractionService);
    sl.registerSingleton<FestivalDetailService>(mockDetailService);
    sl.registerSingleton<FestivalService>(mockFestivalDataService);
    sl.registerSingleton<ArtistFollowService>(mockFollowService);
    sl.registerSingleton<PostService>(mockPostService);
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
    sl.registerFactory<NotificationCountNotifier>(() => NotificationCountNotifier());

    when(() => mockFestivalInteractionService.isLiked(any())).thenAnswer((_) async => false);
    when(() => mockFestivalInteractionService.isAttending(any())).thenAnswer((_) async => false);
    when(() => mockCertService.getMyCertificationStatus(any()))
        .thenAnswer((_) async => MyCertificationStatus.none);
    when(() => mockCertService.getFestivalRating(any())).thenAnswer(
      (_) async => const FestivalRatingSummary(averageRating: 0, ratingCount: 0),
    );
    when(() => mockFollowService.fetchFollowedArtistNames(any())).thenAnswer((_) async => {});
    when(() => mockFollowService.fetchFollowingIds(any())).thenAnswer((_) async => {});
    when(() => mockDetailService.fetchFestivalArtists(any())).thenAnswer((_) async => []);
    when(() => mockDetailService.fetchTimetable(any())).thenAnswer((_) async => []);
    when(() => mockDetailService.fetchBooths(any())).thenAnswer((_) async => []);
    when(() => mockDetailService.fetchSetlist(any())).thenAnswer((_) async => []);
    when(() => mockDetailService.fetchTicketLinks(any())).thenAnswer((_) async => []);
    when(() => mockFestivalDataService.fetchById(any())).thenAnswer((_) async => _poster());
    when(() => mockPostService.fetchFestivalPopularPosts(any())).thenAnswer((_) async => []);
    when(() => mockNotificationCountable.getUnreadCount()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    if (sl.isRegistered<CertificationService>()) sl.unregister<CertificationService>();
    if (sl.isRegistered<FestivalInteractionService>()) {
      sl.unregister<FestivalInteractionService>();
    }
    if (sl.isRegistered<FestivalDetailService>()) sl.unregister<FestivalDetailService>();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userProvider = MockUserProvider();
    when(() => userProvider.currentUserId).thenReturn(1);

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
          child: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: MaterialApp(
              home: Scaffold(body: FestivalInformationFragment(poster: _poster())),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  group('FestivalInformationFragment 렌더링', () {
    testWidgets('포스터/아티스트/게시판/타임테이블/부스맵/셋리스트 섹션을 모두 보여준다', (tester) async {
      await pump(tester);

      expect(find.byType(FestivalPoster), findsOneWidget);
      expect(find.byType(FestivalArtists), findsOneWidget);
      expect(find.byType(FestivalBoard), findsOneWidget);
      expect(find.byType(FestivalTimetable), findsOneWidget);
      expect(find.byType(FestivalBoothMap), findsOneWidget);
      expect(find.byType(FestivalSetlist), findsOneWidget);
      expect(find.text('펜타포트'), findsOneWidget);
    });
  });

  group('FestivalInformationFragment 상세 재조회', () {
    // 홈/목록/검색에서 넘어온 poster는 캐시·미리보기 데이터라 startDate/endDate가
    // 오래됐을 수 있다 — 상세 재조회 결과가 실제로 하위 섹션(타임테이블/부스맵/
    // 포스터) 위젯의 프로퍼티까지 흘러 들어가는지, 그리고 GET /festivals/{id}가
    // 딱 한 번만 호출되는지(FestivalPoster가 예전처럼 또 재조회하면 회귀) 검증한다.
    testWidgets('상세 재조회 결과의 최신 정보가 포스터·타임테이블·부스맵에 전달되고, 조회는 한 번만 일어난다', (tester) async {
      when(() => mockFestivalDataService.fetchById(1)).thenAnswer((_) async => FestivalModel(
            id: 1,
            title: '최신 제목',
            description: '',
            location: '인천 송도달빛축제공원',
            startDate: '2026-09-10',
            endDate: '2026-09-12',
            posterUrl: '',
            latitude: 35.1,
            longitude: 129.0,
          ));

      await pump(tester);
      await tester.pump();

      final poster = tester.widget<FestivalPoster>(find.byType(FestivalPoster));
      expect(poster.poster.title, '최신 제목');

      final timetable = tester.widget<FestivalTimetable>(find.byType(FestivalTimetable));
      expect(timetable.startDate, '2026-09-10');
      expect(timetable.endDate, '2026-09-12');

      final boothMap = tester.widget<FestivalBoothMap>(find.byType(FestivalBoothMap));
      expect(boothMap.festivalLat, 35.1);
      expect(boothMap.festivalLng, 129.0);

      verify(() => mockFestivalDataService.fetchById(1)).called(1);
    });
  });

  group('FestivalInformationFragment 새로고침', () {
    testWidgets('pull-to-refresh 시 아티스트/타임테이블/부스맵/셋리스트를 다시 불러온다', (tester) async {
      await pump(tester);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();
      await tester.pump();

      verify(() => mockDetailService.fetchFestivalArtists(1)).called(2);
      verify(() => mockDetailService.fetchTimetable(1)).called(2);
      verify(() => mockDetailService.fetchBooths(1)).called(2);
      verify(() => mockDetailService.fetchSetlist(1)).called(2);
      // 초기 진입 1회 + pull-to-refresh 1회 = 총 2회 — FestivalPoster가 별도로
      // 또 재조회하면 이 값이 늘어나므로 중복 호출 회귀를 잡아낸다.
      verify(() => mockFestivalDataService.fetchById(1)).called(2);
    });
  });
}
