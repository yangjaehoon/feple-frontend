import 'package:easy_localization/easy_localization.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'login_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setUpSecureStorageMock);
  tearDown(tearDownSecureStorageMock);

  group('VerifyEmailScreen 렌더링', () {
    testWidgets('이메일 주소와 인증 완료/재전송/취소 버튼이 렌더링된다', (tester) async {
      await pumpLoginScreen(
        tester,
        const VerifyEmailScreen(email: 'user@example.com'),
      );

      expect(find.text('verify_email_sent_to'.tr(args: ['user@example.com'])), findsOneWidget);
      expect(find.text('verify_email_done_btn'.tr()), findsOneWidget);
      expect(find.text('verify_email_cancel'.tr()), findsOneWidget);

      // 폴링 타이머가 남아있으면 pending timer 에러가 나므로 dispose되게 정리
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('deleteOnCancel=true면 이메일 변경 링크가 함께 보인다', (tester) async {
      await pumpLoginScreen(
        tester,
        const VerifyEmailScreen(email: 'user@example.com', deleteOnCancel: true),
      );

      expect(find.text('verify_email_change_email'.tr()), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('deleteOnCancel=false(기본값)면 이메일 변경 링크가 보이지 않는다', (tester) async {
      await pumpLoginScreen(
        tester,
        const VerifyEmailScreen(email: 'user@example.com'),
      );

      expect(find.text('verify_email_change_email'.tr()), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('VerifyEmailScreen 재전송 쿨다운', () {
    testWidgets('초기 진입 시 재전송 버튼이 쿨다운으로 비활성화된다', (tester) async {
      await pumpLoginScreen(
        tester,
        const VerifyEmailScreen(email: 'user@example.com'),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
      expect(find.text('verify_email_resend_wait'.tr(args: ['60'])), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('60초가 지나면 재전송 버튼이 활성화된다', (tester) async {
      await pumpLoginScreen(
        tester,
        const VerifyEmailScreen(email: 'user@example.com'),
      );

      await tester.pump(const Duration(seconds: 61));

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('verify_email_resend'.tr()), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('VerifyEmailScreen 인증 확인/취소', () {
    testWidgets('인증 완료 확인 버튼을 탭하면 아직 미인증 메시지를 보여준다', (tester) async {
      await pumpLoginScreen(
        tester,
        const VerifyEmailScreen(email: 'user@example.com'),
      );

      await tester.tap(find.text('verify_email_done_btn'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('verify_email_not_yet'.tr()), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('취소 버튼을 탭하면 확인 다이얼로그가 뜨고, 취소하면 화면이 유지된다', (tester) async {
      await pumpLoginScreen(
        tester,
        const VerifyEmailScreen(email: 'user@example.com'),
      );

      await tester.tap(find.text('verify_email_cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('verify_email_cancel_title'.tr()), findsOneWidget);

      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
