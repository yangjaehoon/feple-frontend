import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/login/s_forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'login_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setUpSecureStorageMock);
  tearDown(tearDownSecureStorageMock);

  group('ForgotPasswordScreen 렌더링', () {
    testWidgets('이메일 필드와 전송 버튼이 렌더링된다', (tester) async {
      await pumpLoginScreen(tester, const ForgotPasswordScreen());

      expect(find.byType(AppTextField), findsOneWidget);
      expect(find.text('send'.tr()), findsOneWidget);
      expect(find.text('reset_password'.tr()), findsOneWidget);
    });

    testWidgets('initialEmail이 주어지면 필드에 미리 채워진다', (tester) async {
      await pumpLoginScreen(
        tester,
        const ForgotPasswordScreen(initialEmail: 'user@example.com'),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'user@example.com');
    });
  });

  group('ForgotPasswordScreen 클라이언트 검증', () {
    testWidgets('이메일이 비어있으면 에러가 표시된다', (tester) async {
      await pumpLoginScreen(tester, const ForgotPasswordScreen());

      await tester.tap(find.text('send'.tr()));
      await tester.pump();

      expect(find.text('enter_email'.tr()), findsOneWidget);
    });

    testWidgets('이메일 형식이 잘못되면 형식 에러가 표시된다', (tester) async {
      await pumpLoginScreen(tester, const ForgotPasswordScreen());

      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.tap(find.text('send'.tr()));
      await tester.pump();

      expect(find.text('enter_valid_email'.tr()), findsOneWidget);
    });

    testWidgets('유효한 이메일로 재전송 시 firebase 오류를 잡아 일반 에러 메시지를 표시한다', (tester) async {
      await pumpLoginScreen(tester, const ForgotPasswordScreen());

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('send'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('unknown_error'.tr()), findsOneWidget);
      // Firebase 미초기화 오류이므로 전송 완료 화면으로는 넘어가지 않는다
      expect(find.text('password_reset_sent_title'.tr()), findsNothing);
    });
  });

  group('ForgotPasswordScreen 네비게이션', () {
    testWidgets('뒤로가기 버튼을 탭하면 이전 화면으로 돌아간다', (tester) async {
      await pumpLoginScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });
  });
}
