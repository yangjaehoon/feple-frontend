import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_support_link_row.dart';
import 'package:feple/login/s_forgot_password.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/login/s_signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'login_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setUpSecureStorageMock);
  tearDown(tearDownSecureStorageMock);

  group('LoginScreen 렌더링', () {
    testWidgets('이메일/비밀번호 필드와 주요 버튼이 렌더링된다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.text('login'.tr()), findsOneWidget);
      expect(find.bySemanticsLabel('kakao_login_btn'.tr()), findsOneWidget);
      // Apple 로그인 버튼은 iOS에서만 노출 (Android는 별도 웹 인증 설정 전까지 숨김)
      expect(
        find.bySemanticsLabel('apple_login_btn'.tr()),
        Platform.isIOS ? findsOneWidget : findsNothing,
      );
      expect(find.bySemanticsLabel('google_login_btn'.tr()), findsOneWidget);
      expect(find.text('signup'.tr()), findsOneWidget);
      expect(find.text('forgot_password'.tr()), findsOneWidget);
    });

    testWidgets('초기 상태에서는 에러 텍스트가 없다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      expect(find.text('enter_email'.tr()), findsNothing);
      expect(find.text('enter_password'.tr()), findsNothing);
    });
  });

  group('LoginScreen 클라이언트 검증', () {
    testWidgets('이메일/비밀번호 모두 빈 채로 로그인하면 두 필드 에러가 표시된다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      await tester.tap(find.text('login'.tr()));
      await tester.pump();

      expect(find.text('enter_email'.tr()), findsOneWidget);
      expect(find.text('enter_password'.tr()), findsOneWidget);
    });

    testWidgets('형식이 잘못된 이메일이면 이메일 형식 에러가 표시된다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'not-an-email');
      await tester.tap(find.text('login'.tr()));
      await tester.pump();

      expect(find.text('enter_valid_email'.tr()), findsOneWidget);
    });

    testWidgets('이메일 입력을 고치면 이메일 에러가 사라진다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      await tester.tap(find.text('login'.tr()));
      await tester.pump();
      expect(find.text('enter_email'.tr()), findsOneWidget);

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'a');
      await tester.pump();

      expect(find.text('enter_email'.tr()), findsNothing);
    });

    testWidgets('유효한 이메일 형식 + 빈 비밀번호는 비밀번호 에러만 표시된다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'user@example.com');
      await tester.tap(find.text('login'.tr()));
      await tester.pump();

      expect(find.text('enter_email'.tr()), findsNothing);
      expect(find.text('enter_password'.tr()), findsOneWidget);
    });
  });

  group('LoginScreen 네비게이션', () {
    testWidgets('회원가입 탭하면 SignupScreen으로 이동한다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      await tester.tap(find.text('signup'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('비밀번호를 잊으셨나요 탭하면 ForgotPasswordScreen으로 이동한다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      await tester.tap(find.text('forgot_password'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });

  group('LoginScreen 로그인 시도 (Firebase 미초기화 환경)', () {
    testWidgets('유효한 입력으로 제출하면 로딩 후 일반 인증 에러로 귀결된다', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());

      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      await tester.enterText(emailField, 'user@example.com');
      await tester.enterText(passwordField, 'password123');

      await tester.tap(find.text('login'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('login_failed'.tr()), findsOneWidget);
    });
  });

  // 반응형 여백 작업 회귀 방지: 문의 링크(SupportLinkRow)가 스크롤 영역 "밖"에
  // 고정돼 있어야 작은 화면에서도 안 밀려난다. 스크롤 여부(픽셀 fit)는 테스트
  // 자산에 번역이 안 실려(미번역 키가 실측보다 길다) 신뢰할 수 없어, 실기기
  // 3종(SE/15/Pro Max) 스크린샷으로 대신 확인했다.
  group('반응형 레이아웃 구조', () {
    void expectFooterPinnedOutsideScroll(WidgetTester tester) {
      expect(find.byType(SupportLinkRow), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(SupportLinkRow),
        ),
        findsNothing,
        reason: '문의 링크가 스크롤 영역 안에 있으면 작은 화면에서 화면 밖으로 밀려난다',
      );
    }

    testWidgets('LoginScreen: 문의 링크가 스크롤 밖에 고정', (tester) async {
      await pumpLoginScreen(tester, const LoginScreen());
      expectFooterPinnedOutsideScroll(tester);
    });

    testWidgets('SignupScreen: 문의 링크가 스크롤 밖에 고정', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen());
      expectFooterPinnedOutsideScroll(tester);
    });
  });
}
