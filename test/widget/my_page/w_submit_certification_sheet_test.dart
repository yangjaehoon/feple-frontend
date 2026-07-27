import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/my_page/w_submit_certification_sheet.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalService extends Mock implements FestivalService {}

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

FestivalModel _festival({int id = 1, String title = '펜타포트'}) {
  return FestivalModel(
    id: id,
    title: title,
    description: '',
    location: '인천',
    startDate: '2026-08-01',
    endDate: '2026-08-03',
    posterUrl: '',
  );
}

void main() {
  late MockCertificationService mockCertService;
  late MockFestivalService mockFestivalService;
  late FakeImagePickerPlatform fakeImagePicker;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockCertService = MockCertificationService();
    mockFestivalService = MockFestivalService();
    fakeImagePicker = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakeImagePicker;

    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
  });

  tearDown(() {
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
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
          // 실제 사용처(showAppBottomSheet)와 동일하게 모달 바텀시트로 열어야
          // 트리거 화면의 Scaffold(ScaffoldMessenger 등록 대상)가 아래 계속
          // 남아있어 스낵바가 정상적으로 보인다 — 풀 라우트로 push하면 트리거
          // 화면이 offstage로 밀려나 스낵바가 표시되지 않는다.
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppBottomSheet<bool>(
                    context,
                    builder: (_) =>
                        SubmitCertificationSheet(certService: mockCertService),
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

  group('SubmitCertificationSheet 페스티벌 목록', () {
    testWidgets('로딩 후 선택기를 보여준다', (tester) async {
      when(() => mockFestivalService.fetchAll())
          .thenAnswer((_) async => [_festival()]);

      await pump(tester);
      await tester.pump();

      expect(find.text('tab_concert'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockFestivalService.fetchAll()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_festival()];
      });

      await pump(tester);
      await tester.pump();

      expect(find.text('retry'.tr()), findsOneWidget);

      await tester.tap(find.text('retry'.tr()));
      await tester.pump();

      expect(find.text('tab_concert'.tr()), findsOneWidget);
    });
  });

  group('SubmitCertificationSheet 페스티벌 검색/선택', () {
    testWidgets('선택기를 탭하면 검색 시트가 열리고 페스티벌을 선택할 수 있다', (tester) async {
      when(() => mockFestivalService.fetchAll()).thenAnswer(
        (_) async => [_festival(id: 1, title: '펜타포트'), _festival(id: 2, title: '워터밤')],
      );

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('tab_concert'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('워터밤'), findsOneWidget);

      await tester.tap(find.text('워터밤'));
      await tester.pumpAndSettle();

      expect(find.text('워터밤'), findsOneWidget);
    });

    testWidgets('검색어를 입력하면 필터링된다', (tester) async {
      when(() => mockFestivalService.fetchAll()).thenAnswer(
        (_) async => [_festival(id: 1, title: '펜타포트'), _festival(id: 2, title: '워터밤')],
      );

      await pump(tester);
      await tester.pump();
      await tester.tap(find.text('tab_concert'.tr()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '워터');
      await tester.pump(AppDimens.animXFast);
      await tester.pumpAndSettle();

      expect(find.text('워터밤'), findsOneWidget);
      expect(find.text('펜타포트'), findsNothing);
    });
  });

  group('SubmitCertificationSheet 제출', () {
    testWidgets('페스티벌을 선택하지 않고 제출하면 안내 스낵바를 보여준다', (tester) async {
      when(() => mockFestivalService.fetchAll()).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed!();
      await tester.pump();

      expect(find.text('select_festival_required_msg'.tr()), findsOneWidget);
    });

    testWidgets('이미지 선택을 취소하면 아무 일도 일어나지 않는다', (tester) async {
      when(() => mockFestivalService.fetchAll())
          .thenAnswer((_) async => [_festival(title: '펜타포트')]);
      fakeImagePicker.imageToReturn = null;

      await pump(tester);
      await tester.pump();
      await tester.tap(find.text('tab_concert'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('펜타포트'));
      await tester.pumpAndSettle();

      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed!();
      await tester.pumpAndSettle();

      verifyNever(() => mockCertService.submit(
            festivalId: any(named: 'festivalId'),
            imageData: any(named: 'imageData'),
          ));
    });

    testWidgets('이미지를 선택하고 제출에 성공하면 성공 상태를 거쳐 시트가 닫힌다', (tester) async {
      when(() => mockFestivalService.fetchAll())
          .thenAnswer((_) async => [_festival(id: 1, title: '펜타포트')]);
      fakeImagePicker.imageToReturn =
          XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'photo.jpg');
      when(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();
      await tester.tap(find.text('tab_concert'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('펜타포트'));
      await tester.pumpAndSettle();

      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed!();
      await tester.pump();
      await tester.pump();

      verify(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).called(1);

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(button.isSuccess, true);

      // 성공 애니메이션 종료 후 pumpAndSettle이 프레임 스케줄 없음으로 조기
      // 종료될 수 있어, pop을 트리거하는 animSuccessDelay를 명시적으로 흘려보낸다
      await tester.pump(AppDimens.animSuccessDelay);
      await tester.pumpAndSettle();
      expect(find.byType(SubmitCertificationSheet), findsNothing);
    });

    testWidgets('제출에 실패하면 에러 스낵바를 보여주고 시트는 유지된다', (tester) async {
      when(() => mockFestivalService.fetchAll())
          .thenAnswer((_) async => [_festival(id: 1, title: '펜타포트')]);
      fakeImagePicker.imageToReturn =
          XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'photo.jpg');
      when(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).thenThrow(Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();
      await tester.tap(find.text('tab_concert'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('펜타포트'));
      await tester.pumpAndSettle();

      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('cert_submit_failed'.tr()), findsOneWidget);
      expect(find.byType(SubmitCertificationSheet), findsOneWidget);
    });
  });
}
