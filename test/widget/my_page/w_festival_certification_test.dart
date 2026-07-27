import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/screen/main/tab/my_page/w_festival_certification.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}

CertificationModel _cert({
  int id = 1,
  CertStatus status = CertStatus.approved,
  String festivalTitle = '펜타포트',
}) {
  return CertificationModel(
    id: id,
    festivalId: 1,
    status: status,
    festivalTitle: festivalTitle,
  );
}

void main() {
  late MockCertificationService mockService;

  setUp(() {
    mockService = MockCertificationService();
    if (sl.isRegistered<CertificationService>()) {
      sl.unregister<CertificationService>();
    }
    sl.registerSingleton<CertificationService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<CertificationService>()) {
      sl.unregister<CertificationService>();
    }
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

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
          child: const MaterialApp(
            home: Scaffold(body: FestivalCertificationWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FestivalCertificationWidget 렌더링', () {
    testWidgets('인증 목록이 있으면 페스티벌 제목과 상태를 보여준다', (tester) async {
      when(() => mockService.getMyCertifications()).thenAnswer(
        (_) async => [_cert(id: 1, festivalTitle: '펜타포트', status: CertStatus.approved)],
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('펜타포트'), findsOneWidget);
      expect(find.text('cert_status_approved'.tr()), findsOneWidget);
    });

    testWidgets('인증 이력이 없으면 빈 상태를 보여준다', (tester) async {
      when(() => mockService.getMyCertifications()).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('cert_no_history'.tr()), findsOneWidget);
    });

    testWidgets('조회 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.getMyCertifications()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_cert(festivalTitle: '복구된 인증')];
      });

      await pump(tester);
      await tester.pump();

      expect(find.text('load_error'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('복구된 인증'), findsOneWidget);
    });
  });

  group('FestivalCertificationWidget 전체보기', () {
    testWidgets('전체보기를 탭하면 인증 목록 화면으로 이동한다', (tester) async {
      when(() => mockService.getMyCertifications()).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('see_all'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(CertificationListScreen), findsOneWidget);
    });
  });
}
