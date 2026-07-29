import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/certification_submit_helper.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}

void main() {
  late MockCertificationService mockCertService;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockCertService = MockCertificationService();
  });

  Future<bool?> pumpAndTap(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    bool? result;
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
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await submitCertification(
                      context,
                      certService: mockCertService,
                      festivalId: 1,
                      imageData: Uint8List.fromList([1, 2, 3]),
                    );
                  },
                  child: const Text('제출'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('제출'));
    await tester.pumpAndSettle();
    return result;
  }

  group('submitCertification', () {
    testWidgets('성공하면 true를 반환한다', (tester) async {
      when(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).thenAnswer((_) async {});

      final result = await pumpAndTap(tester);

      expect(result, isTrue);
    });

    testWidgets('실패하면 에러 스낵바를 보여주고 false를 반환한다', (tester) async {
      when(() => mockCertService.submit(
            festivalId: 1,
            imageData: any(named: 'imageData'),
          )).thenThrow(Exception('업로드 실패'));

      final result = await pumpAndTap(tester);

      expect(result, isFalse);
      expect(find.text('cert_submit_failed'.tr()), findsOneWidget);
    });
  });
}
