import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('KeyboardDismiss', () {
    testWidgets('빈 영역을 탭하면 포커스가 해제된다', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpCommonWidget(
        tester,
        KeyboardDismiss(
          child: Column(
            children: [
              TextField(focusNode: focusNode),
              const SizedBox(height: 200, child: Text('빈 영역')),
            ],
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, true);

      await tester.tap(find.text('빈 영역'));
      await tester.pump();

      expect(focusNode.hasFocus, false);
    });

    testWidgets('child를 그대로 렌더링한다', (tester) async {
      await pumpCommonWidget(
        tester,
        const KeyboardDismiss(child: Text('내용')),
      );

      expect(find.text('내용'), findsOneWidget);
    });
  });
}
