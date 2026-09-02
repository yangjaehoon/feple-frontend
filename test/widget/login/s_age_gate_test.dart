import 'package:easy_localization/easy_localization.dart';
import 'package:feple/login/s_age_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'login_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setUpSecureStorageMock);
  tearDown(tearDownSecureStorageMock);

  group('AgeGateScreen 렌더링', () {
    testWidgets('제목·안내·생년월일 선택·확인 버튼이 렌더링된다', (tester) async {
      await pumpLoginScreen(tester, AgeGateScreen(onVerified: () {}));

      expect(find.text('age_gate_title'.tr()), findsOneWidget);
      expect(find.text('age_gate_subtitle'.tr()), findsOneWidget);
      expect(find.text('age_gate_select_date'.tr()), findsOneWidget);
      expect(find.text('age_gate_submit'.tr()), findsOneWidget);
    });

    testWidgets('예/아니오 형태가 아니라 생년월일을 직접 입력받는다', (tester) async {
      await pumpLoginScreen(tester, AgeGateScreen(onVerified: () {}));

      // "만 14세 이상이신가요?" 같은 이진 질문이 없어야 한다(App Store 심사 요건).
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('뒤로가기로 게이트를 벗어날 수 없다', (tester) async {
      await pumpLoginScreen(tester, AgeGateScreen(onVerified: () {}));

      final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
      expect(popScope.canPop, isFalse);
    });
  });

  group('AgeGateScreen 생년월일 선택', () {
    testWidgets('선택 영역을 누르면 날짜 선택기가 열린다', (tester) async {
      await pumpLoginScreen(tester, AgeGateScreen(onVerified: () {}));

      await tester.tap(find.text('age_gate_select_date'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('날짜를 고르면 선택 영역에 표시된다', (tester) async {
      await pumpLoginScreen(tester, AgeGateScreen(onVerified: () {}));

      await tester.tap(find.text('age_gate_select_date'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 기본 진입 날짜(20년 전) 텍스트로 대체돼 안내 문구가 사라진다.
      expect(find.text('age_gate_select_date'.tr()), findsNothing);
      final year = DateTime.now().year - 20;
      expect(find.textContaining('$year'), findsOneWidget);
    });
  });
}
