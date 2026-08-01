import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_preview_page.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/f_search.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/artist_suggestion_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}
class MockArtistService extends Mock implements ArtistService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}
class MockArtistSuggestionService extends Mock implements ArtistSuggestionService {}
class MockNotificationCountable extends Mock implements NotificationCountable {}
class MockUserProvider extends Mock implements UserProvider {}

FestivalPreview _preview({int id = 1, String title = '축제'}) {
  final now = DateTime.now();
  return FestivalPreview(
    id: id,
    title: title,
    location: '서울',
    posterUrl: 'https://example.com/$id.png',
    startDate: now.add(const Duration(days: 10)).toIso8601String(),
    endDate: now.add(const Duration(days: 12)).toIso8601String(),
  );
}

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
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
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider<FestivalPreviewProvider>(
            create: (_) => FestivalPreviewProvider(sl<FestivalService>()),
          ),
        ],
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(home: SearchFragment()),
        ),
      ),
    ),
  );
  await tester.pump();
  // Swiper autoplay 타이머 때문에 pumpAndSettle을 쓸 수 없다.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFestivalService mockFestivalService;
  late MockArtistService mockArtistService;
  late MockArtistFollowService mockFollowService;
  late MockNotificationCountable mockNotificationCountable;

  setUp(() {
    mockFestivalService = MockFestivalService();
    mockArtistService = MockArtistService();
    mockFollowService = MockArtistFollowService();
    mockNotificationCountable = MockNotificationCountable();

    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(mockArtistService);
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    sl.registerSingleton<ArtistFollowService>(mockFollowService);
    if (sl.isRegistered<ArtistSuggestionService>()) {
      sl.unregister<ArtistSuggestionService>();
    }
    sl.registerSingleton<ArtistSuggestionService>(MockArtistSuggestionService());
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
    sl.registerFactory<NotificationCountNotifier>(() => NotificationCountNotifier());

    when(() => mockFollowService.fetchFollowingIds(any())).thenAnswer((_) async => {});
    when(() => mockNotificationCountable.getUnreadCount()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    if (sl.isRegistered<ArtistSuggestionService>()) sl.unregister<ArtistSuggestionService>();
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    if (sl.isRegistered<NotificationCountNotifier>()) sl.unregister<NotificationCountNotifier>();
  });

  group('SearchFragment 렌더링', () {
    testWidgets('축제 스와이퍼와 아티스트 목록을 함께 보여준다', (tester) async {
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async => FestivalPreviewPage(items: [_preview(title: '서울재즈')], hasMore: false));
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [Artist(id: 1, name: '아이유', genre: 'KPOP', profileImageUrl: '', followerCount: 0)]);

      await _pump(tester);

      expect(find.text('아이유'), findsOneWidget);
      expect(find.text('artist'.tr()), findsOneWidget);
    });
  });

  group('SearchFragment 새로고침', () {
    testWidgets('pull-to-refresh 시 축제/아티스트 목록을 다시 불러온다', (tester) async {
      var festivalCallCount = 0;
      var artistCallCount = 0;
      when(() => mockFestivalService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async {
        festivalCallCount++;
        return FestivalPreviewPage(items: [_preview(title: '축제$festivalCallCount')], hasMore: false);
      });
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async {
        artistCallCount++;
        return <Artist>[];
      });

      await _pump(tester);
      expect(festivalCallCount, 1);
      expect(artistCallCount, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(festivalCallCount, 2);
      expect(artistCallCount, 2);
    });
  });
}
