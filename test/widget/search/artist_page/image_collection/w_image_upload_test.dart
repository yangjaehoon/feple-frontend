import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/photo_destination.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_upload.dart';
import 'package:feple/service/artist_photo_uploadable.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistPhotoUploadable extends Mock implements ArtistPhotoUploadable {}
class MockArtistScheduleService extends Mock implements ArtistScheduleService {}

class FakeImagePickerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {
  XFile? imageToReturn;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => imageToReturn;
}

final _validPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

FestivalPreview _festival({int id = 1, String title = '페스티벌'}) => FestivalPreview(
      id: id,
      title: title,
      location: '서울',
      posterUrl: '',
      startDate: '2026-08-01',
    );

void main() {
  late MockArtistPhotoUploadable mockPhotoService;
  late MockArtistScheduleService mockScheduleService;
  late FakeImagePickerPlatform fakeImagePicker;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockPhotoService = MockArtistPhotoUploadable();
    mockScheduleService = MockArtistScheduleService();
    fakeImagePicker = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakeImagePicker;

    if (sl.isRegistered<ArtistPhotoUploadable>()) {
      sl.unregister<ArtistPhotoUploadable>();
    }
    sl.registerSingleton<ArtistPhotoUploadable>(mockPhotoService);
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    sl.registerSingleton<ArtistScheduleService>(mockScheduleService);
    when(() => mockScheduleService.fetchFestivals(1))
        .thenAnswer((_) async => [_festival()]);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistPhotoUploadable>()) {
      sl.unregister<ArtistPhotoUploadable>();
    }
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
            home: ImageUpload(artistId: 1, artistName: '아티스트'),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pickImage(WidgetTester tester) async {
    fakeImagePicker.imageToReturn = XFile.fromData(_validPngBytes, name: 'a.png');
    await tester.tap(find.byIcon(Icons.add_photo_alternate_rounded));
    await tester.pump();
  }

  group('ImageUpload 렌더링', () {
    testWidgets('아티스트 이름을 보여준다', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.text('아티스트'), findsOneWidget);
    });
  });

  group('ImageUpload 유효성 검사', () {
    testWidgets('사진 없이 제출하면 에러가 표시되고 업로드하지 않는다', (tester) async {
      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('photo_select_required'.tr()), findsOneWidget);
      verifyNever(() => mockPhotoService.uploadPhoto(
            artistId: any(named: 'artistId'),
            imageData: any(named: 'imageData'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            isAnonymous: any(named: 'isAnonymous'),
          ));
    });

    testWidgets('사진은 선택했지만 제목이 없으면 제출되지 않는다', (tester) async {
      await pump(tester);
      await tester.pump();
      await pickImage(tester);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('required_field'.tr()), findsOneWidget);
      verifyNever(() => mockPhotoService.uploadPhoto(
            artistId: any(named: 'artistId'),
            imageData: any(named: 'imageData'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            isAnonymous: any(named: 'isAnonymous'),
          ));
    });
  });

  group('ImageUpload 제출', () {
    testWidgets('사진, 제목, 페스티벌을 모두 채우고 제출하면 업로드된다', (tester) async {
      when(() => mockPhotoService.uploadPhoto(
            artistId: 1,
            imageData: any(named: 'imageData'),
            title: '작품 제목',
            description: '페스티벌',
            isAnonymous: false,
          )).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();
      await pickImage(tester);

      await tester.enterText(find.byType(TextFormField), '작품 제목');
      await tester.tap(find.byType(DropdownButtonFormField<PhotoDestination>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('페스티벌').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      verify(() => mockPhotoService.uploadPhoto(
            artistId: 1,
            imageData: any(named: 'imageData'),
            title: '작품 제목',
            description: '페스티벌',
            isAnonymous: false,
          )).called(1);
      expect(find.byType(ImageUpload), findsNothing);
    });

    testWidgets('업로드 실패(DioException) 시 상세 에러 스낵바를 보여준다', (tester) async {
      when(() => mockPhotoService.uploadPhoto(
            artistId: any(named: 'artistId'),
            imageData: any(named: 'imageData'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            isAnonymous: any(named: 'isAnonymous'),
          )).thenThrow(DioException(requestOptions: RequestOptions(path: '/photos')));

      await pump(tester);
      await tester.pump();
      await pickImage(tester);

      await tester.enterText(find.byType(TextFormField), '작품 제목');
      await tester.tap(find.byType(DropdownButtonFormField<PhotoDestination>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('페스티벌').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('photo_upload_failed_detail'.tr()), findsOneWidget);
      expect(find.byType(ImageUpload), findsOneWidget);
    });
  });

  group('ImageUpload 뒤로가기', () {
    testWidgets('변경 사항이 없으면 확인 없이 바로 닫힌다', (tester) async {
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
                        builder: (_) => const ImageUpload(artistId: 1, artistName: '아티스트'),
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
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ImageUpload), findsNothing);
    });

    testWidgets('제목을 입력한 뒤 뒤로가면 확인 다이얼로그를 보여준다', (tester) async {
      await pump(tester);
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '작성 중');
      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.text('discard_changes'.tr()), findsOneWidget);
      expect(find.byType(ImageUpload), findsOneWidget);
    });
  });
}
