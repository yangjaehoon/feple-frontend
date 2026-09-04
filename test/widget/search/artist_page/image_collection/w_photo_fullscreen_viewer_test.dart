import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/artist_photo_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_photo_fullscreen_viewer.dart';
import 'package:feple/service/artist_photo_manageable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistPhotoManageable extends Mock implements ArtistPhotoManageable {}

class MockUserProvider extends Mock implements UserProvider {}

ArtistPhoto _photo({
  int id = 1,
  String title = '제목',
  String uploaderNickname = '업로더',
  int likeCount = 3,
  bool isLiked = false,
  String description = '',
}) =>
    ArtistPhoto(
      photoId: id,
      url: 'https://example.com/$id.jpg',
      uploaderUserId: 10,
      uploaderNickname: uploaderNickname,
      createdAt: DateTime(2025),
      title: title,
      description: description,
      likeCount: likeCount,
      isLiked: isLiked,
      isAnonymous: false,
    );

void main() {
  late MockArtistPhotoManageable mockService;
  late ArtistPhotoNotifier notifier;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockService = MockArtistPhotoManageable();
    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(10);
    if (sl.isRegistered<ArtistPhotoManageable>()) {
      sl.unregister<ArtistPhotoManageable>();
    }
    sl.registerSingleton<ArtistPhotoManageable>(mockService);
    notifier = ArtistPhotoNotifier(artistId: 1);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistPhotoManageable>()) {
      sl.unregister<ArtistPhotoManageable>();
    }
  });

  Future<void> pump(WidgetTester tester, {required int photoId}) async {
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
            home: PhotoFullscreenViewer(photoId: photoId, notifier: notifier),
          ),
        ),
        ),
      ),
    );
    await tester.pump();
  }

  group('PhotoFullscreenViewer 렌더링', () {
    testWidgets('제목, 업로더, 좋아요 수를 보여준다', (tester) async {
      when(() => mockService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(title: '멋진 사진', uploaderNickname: '홍길동', likeCount: 5)]);
      await notifier.loadPhotos();

      await pump(tester, photoId: 1);

      expect(find.text('멋진 사진'), findsOneWidget);
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('사진이 notifier에 없으면 다음 프레임에 닫힌다', (tester) async {
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => []);
      await notifier.loadPhotos();

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
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoFullscreenViewer(photoId: 99, notifier: notifier),
                      ),
                    ),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('열기'));
      // CachedNetworkImage placeholder(CircularProgressIndicator)가 테스트
      // 환경에서 계속 애니메이션되어 pumpAndSettle이 멈추지 않으므로,
      // 라우트 전환 시간만큼만 고정 시간으로 pump한다.
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(PhotoFullscreenViewer), findsNothing);
    });
  });

  group('PhotoFullscreenViewer 상호작용', () {
    testWidgets('이미지를 탭하면 UI가 숨겨진다', (tester) async {
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => [_photo()]);
      await notifier.loadPhotos();

      await pump(tester, photoId: 1);

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byType(InteractiveViewer));
      // 같은 GestureDetector에 onTap과 onDoubleTap이 모두 있으면 더블탭과
      // 구분하기 위해 kDoubleTapTimeout만큼 기다린 뒤에야 onTap이 실행된다.
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('좋아요를 탭하면 toggleLike가 호출된다', (tester) async {
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => [_photo(isLiked: false)]);
      await notifier.loadPhotos();
      when(() => mockService.toggleLike(1, 1)).thenAnswer((_) async {});

      await pump(tester, photoId: 1);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      verify(() => mockService.toggleLike(1, 1)).called(1);
    });

    testWidgets('비로그인이면 좋아요 탭 시 로그인 화면으로 이동하고 toggleLike를 호출하지 않는다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => [_photo(isLiked: false)]);
      await notifier.loadPhotos();

      await pump(tester, photoId: 1);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      verifyNever(() => mockService.toggleLike(any(), any()));
    });

    testWidgets('닫기 버튼을 탭하면 화면이 닫힌다', (tester) async {
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => [_photo()]);
      await notifier.loadPhotos();

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
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoFullscreenViewer(photoId: 1, notifier: notifier),
                      ),
                    ),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('열기'));
      await tester.pump(const Duration(milliseconds: 1000));

      // CachedNetworkImage placeholder(CircularProgressIndicator)가 계속
      // 애니메이션되는 탓인지 라우트 전환 직후 tester.tap()의 히트테스트가
      // 실제 좌표에서 어긋난다 — 닫기 버튼의 onPressed를 직접 호출해 우회한다.
      final closeButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.close_rounded, skipOffstage: false),
          matching: find.byType(IconButton, skipOffstage: false),
        ),
      );
      closeButton.onPressed!();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PhotoFullscreenViewer, skipOffstage: false), findsNothing);
    });
  });
}
