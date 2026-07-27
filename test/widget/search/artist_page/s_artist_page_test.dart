import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/model/follow_status.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_photo_readable.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistFollowService extends Mock implements ArtistFollowService {}
class MockArtistPhotoReadable extends Mock implements ArtistPhotoReadable {}
class MockPostService extends Mock implements PostService {}
class MockArtistScheduleService extends Mock implements ArtistScheduleService {}
class MockFestivalService extends Mock implements FestivalService {}
class MockSongService extends Mock implements SongService {}
class MockArtistService extends Mock implements ArtistService {}
class MockSongRequestService extends Mock implements SongRequestService {}
class MockUserProvider extends Mock implements UserProvider {}

void _registerService<T extends Object>(T instance) {
  if (sl.isRegistered<T>()) sl.unregister<T>();
  sl.registerSingleton<T>(instance);
}

void _unregisterService<T extends Object>() {
  if (sl.isRegistered<T>()) sl.unregister<T>();
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
          child: const MaterialApp(
            home: ArtistScreen(
              artistName: '아이유',
              artistId: 1,
              followerCount: 100,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // MainImageSwiper의 자동 스크롤 Timer 때문에 pumpAndSettle을 쓸 수 없다.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  late MockArtistFollowService mockFollowService;
  late MockPostService mockPostService;
  late MockArtistScheduleService mockScheduleService;
  late MockSongService mockSongService;
  late MockArtistService mockArtistService;

  setUp(() {
    mockFollowService = MockArtistFollowService();
    mockPostService = MockPostService();
    mockScheduleService = MockArtistScheduleService();
    mockSongService = MockSongService();
    mockArtistService = MockArtistService();

    _registerService<ArtistFollowService>(mockFollowService);
    _registerService<ArtistPhotoReadable>(MockArtistPhotoReadable());
    _registerService<PostService>(mockPostService);
    _registerService<ArtistScheduleService>(mockScheduleService);
    _registerService<FestivalService>(MockFestivalService());
    _registerService<SongService>(mockSongService);
    _registerService<ArtistService>(mockArtistService);
    _registerService<SongRequestService>(MockSongRequestService());
  });

  tearDown(() {
    _unregisterService<ArtistFollowService>();
    _unregisterService<ArtistPhotoReadable>();
    _unregisterService<PostService>();
    _unregisterService<ArtistScheduleService>();
    _unregisterService<FestivalService>();
    _unregisterService<SongService>();
    _unregisterService<ArtistService>();
    _unregisterService<SongRequestService>();
  });

  group('ArtistScreen 렌더링', () {
    testWidgets('팔로우/사진 로드가 실패해도 나머지 섹션은 정상 렌더링된다', (tester) async {
      // ArtistFollowNotifier.init()/ArtistSwiperPhotosNotifier.load()는 async 메서드
      // 내부에서 try/catch로 감싸져 있어 unstub 상태로도 안전하지만, ArtistSchedule/
      // ArtistSongs/RelatedArtists/ArtistBoard는 initState에서 동기적으로
      // `_future = _fetchX();` 형태로 Future를 대입하기 때문에(try/catch 없음) 실제
      // 서비스처럼 반드시 Future를 반환해야 한다 — 그렇지 않으면 unstub된 Mock 호출이
      // 동기적으로 타입 에러를 던져 위젯 빌드가 즉시 크래시한다.
      when(() => mockPostService.fetchArtistPosts(1)).thenAnswer((_) async => []);
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async => []);
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);
      when(() => mockArtistService.fetchRelatedArtists(1)).thenAnswer((_) async => []);

      await _pump(tester);

      expect(find.text('아이유'), findsWidgets); // 앱바 + 헤더
      expect(find.text('artist_schedule_title'.tr(args: ['아이유'])), findsOneWidget);
      expect(find.text('artist_songs_title'.tr(args: ['아이유'])), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('각 서비스가 정상 응답하면 섹션 데이터가 렌더링된다', (tester) async {
      when(() => mockFollowService.getFollowStatus(1))
          .thenAnswer((_) async => FollowStatus(followed: false, followerCount: 100));
      when(() => mockPostService.fetchArtistPosts(1)).thenAnswer((_) async => []);
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async => [
            ArtistScheduleModel(
              festivalId: 1,
              title: '서울재즈',
              startDate: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
              eventType: EventType.festival,
              coArtists: const [],
            ),
          ]);
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => [
            const SongModel(
              id: 1,
              title: '좋은날',
              youtubeVideoId: 'abc123',
              youtubeUrl: 'https://youtube.com/watch?v=abc123',
            ),
          ]);
      when(() => mockArtistService.fetchRelatedArtists(1)).thenAnswer((_) async => []);

      await _pump(tester);

      expect(find.text('서울재즈'), findsOneWidget);
      expect(find.text('좋은날'), findsOneWidget);
    });

    testWidgets('데이터가 없으면 각 섹션에 빈 상태를 보여준다', (tester) async {
      when(() => mockFollowService.getFollowStatus(1))
          .thenAnswer((_) async => FollowStatus(followed: false, followerCount: 100));
      when(() => mockPostService.fetchArtistPosts(1)).thenAnswer((_) async => []);
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async => []);
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);
      when(() => mockArtistService.fetchRelatedArtists(1)).thenAnswer((_) async => []);

      await _pump(tester);

      expect(find.text('no_schedule'.tr()), findsOneWidget);
      expect(find.text('no_songs'.tr()), findsOneWidget);
    });
  });

  group('ArtistScreen 팔로우', () {
    testWidgets('팔로우 버튼을 탭하면 상태가 토글되고 성공 스낵바를 보여준다', (tester) async {
      when(() => mockFollowService.getFollowStatus(1))
          .thenAnswer((_) async => FollowStatus(followed: false, followerCount: 100));
      when(() => mockFollowService.follow(1)).thenAnswer((_) async {});
      when(() => mockPostService.fetchArtistPosts(1)).thenAnswer((_) async => []);
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async => []);
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);
      when(() => mockArtistService.fetchRelatedArtists(1)).thenAnswer((_) async => []);

      await _pump(tester);

      expect(find.text('follow'.tr()), findsOneWidget);

      await tester.tap(find.text('follow'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockFollowService.follow(1)).called(1);
      expect(find.text('following'.tr()), findsOneWidget); // 버튼 라벨이 팔로잉으로 전환
      expect(find.text('follow_done'.tr()), findsOneWidget); // 성공 스낵바
    });

    testWidgets('로그인하지 않은 상태에서 팔로우를 탭하면 안내 스낵바를 보여준다', (tester) async {
      when(() => mockFollowService.getFollowStatus(1))
          .thenAnswer((_) async => FollowStatus(followed: false, followerCount: 100));
      when(() => mockPostService.fetchArtistPosts(1)).thenAnswer((_) async => []);
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async => []);
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);
      when(() => mockArtistService.fetchRelatedArtists(1)).thenAnswer((_) async => []);

      await _pump(tester, userId: null);

      await tester.tap(find.text('follow'.tr()));
      await tester.pump();

      expect(find.text('no_login_info'.tr()), findsOneWidget);
      verifyNever(() => mockFollowService.follow(any()));
    });
  });
}
