import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_certification_bottom_sheet.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}

// Image.memory가 디코딩할 수 있는 최소 유효 PNG(1x1 투명 픽셀) 바이트 —
// 임의 바이트([1,2,3] 등)는 "Invalid image data" 예외를 던진다
final Uint8List _validPngBytes = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0,
  0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84, 120,
  156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68,
  174, 66, 96, 130,
]);

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

void main() {
  late MockCertificationService mockCertService;
  late FakeImagePickerPlatform fakeImagePicker;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockCertService = MockCertificationService();
    fakeImagePicker = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakeImagePicker;
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
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppBottomSheet(
                    context,
                    builder: (_) => CertificationBottomSheet(
                      festivalName: '펜타포트',
                      festivalId: 1,
                      certService: mockCertService,
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
  }

  group('CertificationBottomSheet 렌더링', () {
    testWidgets('제목/설명/사진 안내를 보여준다', (tester) async {
      await pump(tester);

      expect(find.text('cert_title'.tr()), findsOneWidget);
      expect(find.text('cert_description'.tr(args: ['펜타포트'])), findsOneWidget);
      expect(find.text('cert_photo_hint'.tr()), findsOneWidget);
    });

    testWidgets('사진을 선택하지 않으면 제출 버튼이 비활성화된다', (tester) async {
      await pump(tester);

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(button.onPressed, isNull);
    });
  });

  group('CertificationBottomSheet 사진 선택', () {
    testWidgets('사진을 선택하면 미리보기와 함께 제출 버튼이 활성화된다', (tester) async {
      fakeImagePicker.imageToReturn =
          XFile.fromData(_validPngBytes, name: 'photo.jpg');

      await pump(tester);
      await tester.tap(find.text('cert_photo_hint'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('사진 선택을 취소하면 그대로 유지된다', (tester) async {
      fakeImagePicker.imageToReturn = null;

      await pump(tester);
      await tester.tap(find.text('cert_photo_hint'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('cert_photo_hint'.tr()), findsOneWidget);
    });
  });

  group('CertificationBottomSheet 제출', () {
    testWidgets('제출에 성공하면 성공 스낵바를 보여주고 시트가 닫힌다', (tester) async {
      fakeImagePicker.imageToReturn =
          XFile.fromData(_validPngBytes, name: 'photo.jpg');
      when(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).thenAnswer((_) async {});

      await pump(tester);
      await tester.tap(find.text('cert_photo_hint'.tr()));
      await tester.pumpAndSettle();

      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed!();
      await tester.pumpAndSettle();

      verify(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).called(1);
      expect(find.text('cert_submit_success'.tr()), findsOneWidget);
      expect(find.byType(CertificationBottomSheet), findsNothing);
    });

    testWidgets('제출에 실패하면 에러 스낵바를 보여주고 시트는 유지된다', (tester) async {
      fakeImagePicker.imageToReturn =
          XFile.fromData(_validPngBytes, name: 'photo.jpg');
      when(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).thenThrow(Exception('네트워크 오류'));

      await pump(tester);
      await tester.tap(find.text('cert_photo_hint'.tr()));
      await tester.pumpAndSettle();

      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('cert_submit_failed'.tr()), findsOneWidget);
      expect(find.byType(CertificationBottomSheet), findsOneWidget);
    });
  });
}
