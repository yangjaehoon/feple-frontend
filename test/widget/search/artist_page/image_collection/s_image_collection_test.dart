import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/s_image_collection.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_upload.dart';
import 'package:feple/service/artist_photo_manageable.dart';
import 'package:feple/service/artist_photo_uploadable.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/service/report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistPhotoManageable extends Mock implements ArtistPhotoManageable {}
class MockArtistPhotoUploadable extends Mock implements ArtistPhotoUploadable {}
class MockArtistScheduleService extends Mock implements ArtistScheduleService {}
class MockReportService extends Mock implements ReportService {}
class MockUserProvider extends Mock implements UserProvider {}

ArtistPhoto _photo({int id = 1, String title = '제목'}) => ArtistPhoto(
      photoId: id,
      url: 'https://example.com/$id.jpg',
      uploaderUserId: 10,
      uploaderNickname: '업로더',
      createdAt: DateTime(2025),
      title: title,
      description: '',
      likeCount: 0,
      isLiked: false,
      isAnonymous: false,
    );

void main() {
  late MockArtistPhotoManageable mockPhotoService;

  setUp(() {
    mockPhotoService = MockArtistPhotoManageable();

    if (sl.isRegistered<ArtistPhotoManageable>()) {
      sl.unregister<ArtistPhotoManageable>();
    }
    sl.registerSingleton<ArtistPhotoManageable>(mockPhotoService);

    // ImageUpload(FAB 목적지)의 필드 초기화에서 sl<ArtistPhotoUploadable>()/
    // sl<ArtistScheduleService>()를 즉시 호출하므로 함께 등록해야 한다.
    if (sl.isRegistered<ArtistPhotoUploadable>()) {
      sl.unregister<ArtistPhotoUploadable>();
    }
    sl.registerSingleton<ArtistPhotoUploadable>(MockArtistPhotoUploadable());

    if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
    sl.registerSingleton<ReportService>(MockReportService());

    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    final mockScheduleService = MockArtistScheduleService();
    when(() => mockScheduleService.fetchFestivals(any())).thenAnswer((_) async => []);
    sl.registerSingleton<ArtistScheduleService>(mockScheduleService);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistPhotoManageable>()) {
      sl.unregister<ArtistPhotoManageable>();
    }
    if (sl.isRegistered<ArtistPhotoUploadable>()) {
      sl.unregister<ArtistPhotoUploadable>();
    }
    if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userProvider = MockUserProvider();
    when(() => userProvider.currentUserId).thenReturn(10);

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
            child: MaterialApp(
              home: ImageCollectionScreen(artistId: 1, artistName: '아티스트'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ImageCollectionScreen 렌더링', () {
    testWidgets('사진 목록과 타이틀을 보여준다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(title: '사진1')]);

      await pump(tester);
      await tester.pump();

      expect(find.text('photo_collection_title'.tr()), findsOneWidget);
      expect(find.text('사진1'), findsOneWidget);
    });
  });

  group('ImageCollectionScreen 새로고침', () {
    testWidgets('pull-to-refresh 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockPhotoService.fetchPhotos(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      await pump(tester);
      await tester.pump();
      expect(callCount, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });

  group('ImageCollectionScreen 업로드', () {
    testWidgets('FAB을 탭하면 업로드 화면으로 이동한다', (tester) async {
      when(() => mockPhotoService.fetchPhotos(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ImageUpload, skipOffstage: false), findsOneWidget);
    });
  });
}
