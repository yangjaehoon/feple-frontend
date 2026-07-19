import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'common_widget_test_harness.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late MockUserService mockUserService;

  setUp(() {
    mockUserService = MockUserService();
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    sl.registerSingleton<UserService>(mockUserService);
  });

  tearDown(() {
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
  });

  Future<void> tapCheck(WidgetTester tester) async {
    await tester.tap(find.byType(LoadingButton));
    await tester.pumpAndSettle();
  }

  group('NicknameField 렌더링', () {
    testWidgets('initialValue가 컨트롤러에 미리 채워진다', (tester) async {
      await pumpCommonWidget(
        tester,
        const NicknameField(initialValue: '기존닉네임'),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '기존닉네임');
    });
  });

  group('NicknameField 클라이언트 검증', () {
    testWidgets('빈 닉네임으로 확인하면 입력 요청 에러가 표시된다', (tester) async {
      await pumpCommonWidget(tester, const NicknameField());

      await tapCheck(tester);

      expect(find.text('enter_nickname'.tr()), findsOneWidget);
      verifyNever(() => mockUserService.checkNicknameAvailability(any(),
          excludeUserId: any(named: 'excludeUserId')));
    });

    testWidgets('닉네임이 너무 짧으면 길이 에러가 표시된다', (tester) async {
      await pumpCommonWidget(tester, const NicknameField());

      await tester.enterText(find.byType(TextField), 'a');
      await tapCheck(tester);

      expect(find.text('nickname_length_error'.tr()), findsOneWidget);
    });

    testWidgets('닉네임이 너무 길면 길이 에러가 표시된다', (tester) async {
      // TextField의 maxLength가 UI 입력 단계에서 8자로 잘라내므로, 컨트롤러에
      // 직접 대입해 checkNickname()의 길이 검증 분기를 우회 없이 확인한다.
      final key = GlobalKey<NicknameFieldState>();
      await pumpCommonWidget(tester, NicknameField(key: key));

      key.currentState!.controller.text = '너무길게된닉네임입니다';
      await key.currentState!.checkNickname();
      await tester.pump();

      expect(find.text('nickname_length_error'.tr()), findsOneWidget);
    });
  });

  group('NicknameField 서버 확인', () {
    testWidgets('사용 가능하면 available 메시지가 표시되고 콜백이 true로 호출된다', (tester) async {
      bool? received;
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: true, code: 'OK'));

      await pumpCommonWidget(
        tester,
        NicknameField(onStateChanged: (v) => received = v),
      );
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);

      expect(find.text('nickname_available'.tr()), findsOneWidget);
      expect(received, true);
    });

    testWidgets('DUPLICATE 코드면 중복 사용중 메시지가 표시된다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: false, code: 'DUPLICATE'));

      await pumpCommonWidget(tester, const NicknameField());
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);

      expect(find.text('nickname_already_in_use'.tr()), findsOneWidget);
    });

    testWidgets('INVALID_FORMAT 코드면 형식 오류 메시지가 표시된다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: false, code: 'INVALID_FORMAT'));

      await pumpCommonWidget(tester, const NicknameField());
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);

      expect(find.text('nickname_invalid_chars'.tr()), findsOneWidget);
    });

    testWidgets('BAD_WORD 코드면 금칙어 메시지가 표시된다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: false, code: 'BAD_WORD'));

      await pumpCommonWidget(tester, const NicknameField());
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);

      expect(find.text('nickname_bad_word'.tr()), findsOneWidget);
    });

    testWidgets('알 수 없는 코드면 기본 사용불가 메시지가 표시된다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: false, code: 'ETC'));

      await pumpCommonWidget(tester, const NicknameField());
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);

      expect(find.text('nickname_invalid'.tr()), findsOneWidget);
    });

    testWidgets('서비스 예외 발생 시 확인 실패 메시지가 표시된다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenThrow(Exception('network error'));

      await pumpCommonWidget(tester, const NicknameField());
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);

      expect(find.text('nickname_check_error'.tr()), findsOneWidget);
    });

    testWidgets('excludeUserId를 지정하면 서비스 호출에 그대로 전달된다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: true, code: 'OK'));

      await pumpCommonWidget(
        tester,
        const NicknameField(excludeUserId: 42),
      );
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);

      verify(() => mockUserService.checkNicknameAvailability('닉네임', excludeUserId: 42))
          .called(1);
    });
  });

  group('NicknameField 상태 초기화', () {
    testWidgets('확인 후 텍스트를 다시 수정하면 결과 메시지가 사라지고 콜백이 null로 호출된다', (tester) async {
      bool? received = false;
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: true, code: 'OK'));

      await pumpCommonWidget(
        tester,
        NicknameField(onStateChanged: (v) => received = v),
      );
      await tester.enterText(find.byType(TextField), '닉네임');
      await tapCheck(tester);
      expect(find.text('nickname_available'.tr()), findsOneWidget);

      await tester.enterText(find.byType(TextField), '닉네임2');
      await tester.pump();

      expect(find.text('nickname_available'.tr()), findsNothing);
      expect(received, isNull);
    });
  });

  group('NicknameField GlobalKey 접근', () {
    testWidgets('showError를 호출하면 에러 메시지가 표시된다', (tester) async {
      final key = GlobalKey<NicknameFieldState>();
      await pumpCommonWidget(tester, NicknameField(key: key));

      key.currentState!.showError('강제 에러 메시지');
      await tester.pump();

      expect(find.text('강제 에러 메시지'), findsOneWidget);
      expect(key.currentState!.available, false);
    });

    testWidgets('currentNickname/lastCheckedNickname을 외부에서 조회할 수 있다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability(any(),
              excludeUserId: any(named: 'excludeUserId')))
          .thenAnswer((_) async => const NicknameCheckResult(available: true, code: 'OK'));

      final key = GlobalKey<NicknameFieldState>();
      await pumpCommonWidget(tester, NicknameField(key: key));

      await tester.enterText(find.byType(TextField), ' 닉네임 ');
      expect(key.currentState!.currentNickname, '닉네임');

      await tapCheck(tester);
      expect(key.currentState!.lastCheckedNickname, '닉네임');
      expect(key.currentState!.available, true);
    });
  });
}
