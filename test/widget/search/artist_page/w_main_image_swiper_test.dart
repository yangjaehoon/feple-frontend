import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_main_image_swiper.dart';
import 'package:feple/service/artist_photo_readable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistPhotoReadable extends Mock implements ArtistPhotoReadable {}
class MockArtistFollowNotifier extends Mock implements ArtistFollowNotifier {}
class MockUserProvider extends Mock implements UserProvider {}

ArtistPhoto _photo(int id) => ArtistPhoto(
      photoId: id,
      url: 'https://example.com/$id.jpg',
      uploaderUserId: 10,
      uploaderNickname: 'user',
      createdAt: DateTime(2025),
      title: 'title $id',
      description: 'desc $id',
      likeCount: 0,
      isLiked: false,
      isAnonymous: false,
    );

void main() {
  late MockArtistPhotoReadable mockPhotoService;
  late MockArtistFollowNotifier mockFollowNotifier;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockPhotoService = MockArtistPhotoReadable();
    if (sl.isRegistered<ArtistPhotoReadable>()) {
      sl.unregister<ArtistPhotoReadable>();
    }
    sl.registerSingleton<ArtistPhotoReadable>(mockPhotoService);

    mockFollowNotifier = MockArtistFollowNotifier();
    when(() => mockFollowNotifier.isFollowed).thenReturn(false);
    when(() => mockFollowNotifier.isLoading).thenReturn(false);
    when(() => mockFollowNotifier.initFailed).thenReturn(false);
    when(() => mockFollowNotifier.followCount).thenReturn(0);
    when(() => mockFollowNotifier.followStatusKey).thenReturn('follow_done');

    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(1);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistPhotoReadable>()) {
      sl.unregister<ArtistPhotoReadable>();
    }
  });

  Future<void> pump(WidgetTester tester, {GlobalKey<MainImageSwiperState>? key}) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        startLocale: const Locale('ko'),
        fallbackLocale: const Locale('ko'),
        path: 'assets/translations',
        useOnlyLangCode: true,
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (_) {},
            child: MaterialApp(
              home: Scaffold(
                body: MainImageSwiper(
                  key: key,
                  artistName: '아티스트',
                  artistId: 1,
                  followNotifier: mockFollowNotifier,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Timer.periodic(3초)로 자동 스크롤을 시작하므로, 테스트 종료 전 반드시
    // 위젯을 언마운트해 dispose()가 타이머를 취소하게 한다 — 그렇지 않으면
    // "A Timer is still pending" 실패로 테스트가 깨진다.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
    });
  }

  group('MainImageSwiper 렌더링', () {
    testWidgets('사진이 있으면 캐러셀과 팔로우 헤더를 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1, limit: 10))
          .thenAnswer((_) async => [_photo(1), _photo(2), _photo(3)]);

      await pump(tester);
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('아티스트'), findsOneWidget);
    });

    testWidgets('사진이 없으면 캐러셀 없이 기본 배경만 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1, limit: 10)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.text('아티스트'), findsOneWidget);
    });

    testWidgets('로드 실패해도 크래시 없이 기본 배경을 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1, limit: 10))
          .thenAnswer((_) async => throw Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.text('아티스트'), findsOneWidget);
    });
  });

  group('MainImageSwiper 새로고침', () {
    testWidgets('refresh를 호출하면 사진을 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockPhotoService.fetchPhotos(1, limit: 10)).thenAnswer((_) async {
        callCount++;
        return [_photo(1)];
      });
      final key = GlobalKey<MainImageSwiperState>();

      await pump(tester, key: key);
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
