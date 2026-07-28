import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_edit_photo_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_collection.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_photo_fullscreen_viewer.dart';
import 'package:feple/service/artist_photo_manageable.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/service/report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 사진 이미지의 CachedNetworkImage placeholder가 테스트 환경에서 계속
// 애니메이션되어 pumpAndSettle이 멈추지 않는다. 대신 짧은 프레임을 여러 번 나눠
// pump해 팝업/라우트 전환 애니메이션이 실제로 완료되도록 한다 — 큰 duration을
// 한 번에 pump하면 오버레이 라우트가 아직 히트테스트 가능한 상태로 전환되지 않는
// 경우가 있었다.
Future<void> _pumpFrames(WidgetTester tester, {int count = 20}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class MockArtistPhotoManageable extends Mock implements ArtistPhotoManageable {}
class MockReportService extends Mock implements ReportService {}
class MockArtistScheduleService extends Mock implements ArtistScheduleService {}
class MockUserProvider extends Mock implements UserProvider {}

ArtistPhoto _photo({
  int id = 1,
  String title = '제목',
  int? uploaderUserId = 10,
  int likeCount = 3,
  bool isLiked = false,
  String description = '',
}) =>
    ArtistPhoto(
      photoId: id,
      url: 'https://example.com/$id.jpg',
      uploaderUserId: uploaderUserId,
      uploaderNickname: '업로더',
      createdAt: DateTime(2025),
      title: title,
      description: description,
      likeCount: likeCount,
      isLiked: isLiked,
      isAnonymous: false,
    );

void main() {
  late MockArtistPhotoManageable mockPhotoService;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockPhotoService = MockArtistPhotoManageable();
    if (sl.isRegistered<ArtistPhotoManageable>()) {
      sl.unregister<ArtistPhotoManageable>();
    }
    sl.registerSingleton<ArtistPhotoManageable>(mockPhotoService);

    if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
    sl.registerSingleton<ReportService>(MockReportService());

    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    final mockScheduleService = MockArtistScheduleService();
    when(() => mockScheduleService.fetchFestivals(any())).thenAnswer((_) async => []);
    sl.registerSingleton<ArtistScheduleService>(mockScheduleService);

    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(10);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistPhotoManageable>()) {
      sl.unregister<ArtistPhotoManageable>();
    }
    if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
  });

  Future<void> pump(WidgetTester tester, {GlobalKey<ImageCollectionWidgetState>? key}) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
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
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (_) {},
            child: MaterialApp(
              home: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    ImageCollectionWidget(key: key, artistId: 1, artistName: '아티스트'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ImageCollectionWidget 렌더링', () {
    testWidgets('사진 목록을 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(title: '사진1')]);

      await pump(tester);
      await tester.pump();

      expect(find.text('사진1'), findsOneWidget);
    });

    testWidgets('사진이 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('photo_no_photos'.tr()), findsOneWidget);
    });
  });

  group('ImageCollectionWidget 좋아요', () {
    testWidgets('좋아요 오버레이를 탭하면 toggleLike가 호출된다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(isLiked: false)]);
      when(() => mockPhotoService.toggleLike(1, 1)).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      verify(() => mockPhotoService.toggleLike(1, 1)).called(1);
    });
  });

  group('ImageCollectionWidget 사진 탭', () {
    testWidgets('사진을 탭하면 전체화면 뷰어로 이동한다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo()]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byType(CachedNetworkImage));
      await _pumpFrames(tester);

      expect(find.byType(PhotoFullscreenViewer, skipOffstage: false), findsOneWidget);
    });
  });

  group('ImageCollectionWidget 업로더 메뉴', () {
    testWidgets('본인 사진이면 수정/삭제 메뉴를 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(uploaderUserId: 10)]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await _pumpFrames(tester);

      expect(find.text('photo_edit_action'.tr()), findsOneWidget);
      expect(find.text('msg_delete'.tr()), findsOneWidget);
    });

    testWidgets('수정을 탭하면 수정 시트가 열린다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(uploaderUserId: 10)]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await _pumpFrames(tester);
      await tester.tap(find.text('photo_edit_action'.tr()));
      await _pumpFrames(tester);

      expect(find.byType(EditPhotoSheet), findsOneWidget);
    });

    testWidgets('삭제를 탭하고 확인하면 deletePhoto가 호출된다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(uploaderUserId: 10)]);
      when(() => mockPhotoService.deletePhoto(1, 1)).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await _pumpFrames(tester);
      await tester.tap(find.text('msg_delete'.tr()));
      await _pumpFrames(tester);

      expect(find.text('photo_delete_confirm'.tr()), findsOneWidget);
      await tester.tap(find.text('msg_delete'.tr()).last);
      await tester.pump();

      verify(() => mockPhotoService.deletePhoto(1, 1)).called(1);
    });
  });

  group('ImageCollectionWidget 타인 사진 메뉴', () {
    testWidgets('본인 사진이 아니면 신고 메뉴만 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(uploaderUserId: 999)]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await _pumpFrames(tester);

      expect(find.text('report_photo'.tr()), findsOneWidget);
      expect(find.text('photo_edit_action'.tr()), findsNothing);
    });

    testWidgets('신고를 탭하면 신고 시트가 열린다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(uploaderUserId: 999)]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await _pumpFrames(tester);
      await tester.tap(find.text('report_photo'.tr()));
      await _pumpFrames(tester);

      expect(find.text('report_photo'.tr()), findsOneWidget);
    });
  });

  group('ImageCollectionWidget 새로고침', () {
    testWidgets('refresh를 호출하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockPhotoService.fetchPhotos(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });
      final key = GlobalKey<ImageCollectionWidgetState>();

      await pump(tester, key: key);
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
