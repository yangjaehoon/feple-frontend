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
    mockFollowService = MockArtistFollowService();
    mockPostService = MockPostService();
    mockNotificationCountable = MockNotificationCountable();

    if (sl.isRegistered<CertificationService>()) sl.unregister<CertificationService>();
    if (sl.isRegistered<FestivalInteractionService>()) {
      sl.unregister<FestivalInteractionService>();
    }
    if (sl.isRegistered<FestivalDetailService>()) sl.unregister<FestivalDetailService>();
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }

    sl.registerSingleton<CertificationService>(mockCertService);
    sl.registerSingleton<FestivalInteractionService>(mockFestivalInteractionService);
    sl.registerSingleton<FestivalDetailService>(mockDetailService);
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
    when(() => mockPostService.fetchFestivalPopularPosts(any())).thenAnswer((_) async => []);
    when(() => mockNotificationCountable.getUnreadCount()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    if (sl.isRegistered<CertificationService>()) sl.unregister<CertificationService>();
    if (sl.isRegistered<FestivalInteractionService>()) {
      sl.unregister<FestivalInteractionService>();
    }
    if (sl.isRegistered<FestivalDetailService>()) sl.unregister<FestivalDetailService>();
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
    });
  });
}
