import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/login/s_signup.dart';
import 'package:feple/login/w_password_checklist.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'login_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserService mockUserService;

  setUp(() {
    setUpSecureStorageMock();
    mockUserService = MockUserService();
  });
  tearDown(tearDownSecureStorageMock);

  group('SignupScreen 렌더링', () {
    testWidgets('이메일/닉네임/비밀번호 필드와 회원가입 버튼이 렌더링된다', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.byType(NicknameField), findsOneWidget);
      expect(find.text('register'.tr()), findsOneWidget);
      expect(find.text('already_have_account'.tr()), findsOneWidget);
    });

    testWidgets('비밀번호 미입력 시 PasswordChecklist가 보이지 않는다', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      expect(find.byType(PasswordChecklist), findsNothing);
    });

    testWidgets('비밀번호 입력 시 PasswordChecklist가 나타난다', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'a');
      await tester.pump();

      expect(find.byType(PasswordChecklist), findsOneWidget);
    });
  });

  group('SignupScreen 클라이언트 검증', () {
    testWidgets('모든 필드가 비어있으면 이메일/비밀번호/닉네임 에러가 모두 표시된다', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      await tester.tap(find.text('register'.tr()));
      await tester.pump();

      expect(find.text('enter_email'.tr()), findsOneWidget);
      expect(find.text('enter_password'.tr()), findsOneWidget);
      expect(find.text('enter_nickname'.tr()), findsOneWidget);
    });

    testWidgets('형식이 잘못된 이메일이면 이메일 형식 에러가 표시된다', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'not-an-email');
      await tester.tap(find.text('register'.tr()));
      await tester.pump();

      expect(find.text('enter_valid_email'.tr()), findsOneWidget);
    });

    testWidgets('약한 비밀번호는 조건 미충족 에러 메시지가 표시된다', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'abc');
      await tester.tap(find.text('register'.tr()));
      await tester.pump();

      expect(find.textContaining('password_min_length'.tr()), findsOneWidget);
    });

    testWidgets('닉네임을 입력했지만 중복확인을 하지 않으면 확인 요청 에러가 표시된다', (tester) async {
      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      final emailField = find.byType(TextField).first;
      final nicknameField = find.byType(TextField).at(1);
      final passwordField = find.byType(TextField).last;
      await tester.enterText(emailField, 'user@example.com');
      await tester.enterText(nicknameField, '테스터닉네임');
      await tester.enterText(passwordField, 'Abcdef1!');

      await tester.tap(find.text('register'.tr()));
      await tester.pump();

      expect(find.text('nickname_check_req'.tr()), findsOneWidget);
    });

    testWidgets('닉네임 중복확인 통과 + 유효한 이메일/비밀번호면 검증 에러 없이 가입을 시도한다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(), excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: true, code: 'OK'));

      await pumpLoginScreen(tester, const SignupScreen(), userService: mockUserService);

      final emailField = find.byType(TextField).first;
      final nicknameField = find.byType(TextField).at(1);
      final passwordField = find.byType(TextField).last;
      await tester.enterText(emailField, 'user@example.com');
      await tester.enterText(nicknameField, '테스터닉네임');
      await tester.tap(find.text('check_duplication'.tr()));
      await tester.pump();
      expect(find.text('nickname_available'.tr()), findsOneWidget);

      await tester.enterText(passwordField, 'Abcdef1!');
      await tester.tap(find.text('register'.tr()));
      await tester.pump();

      expect(find.text('enter_email'.tr()), findsNothing);
      expect(find.text('enter_password'.tr()), findsNothing);
      expect(find.text('nickname_check_req'.tr()), findsNothing);
    });
  });

  group('SignupScreen 네비게이션', () {
    testWidgets('로그인 링크를 탭하면 이전 화면으로 돌아간다', (tester) async {
      await pumpLoginScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
        userService: mockUserService,
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      await tester.tap(find.text('login'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsNothing);
      expect(find.text('go'), findsOneWidget);
    });
  });
}
