import 'package:feple/common/widget/w_empty_expanded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('EmptyExpanded', () {
    testWidgets('기본 flex는 1이다', (tester) async {
      await pumpCommonWidget(
        tester,
        const Row(children: [EmptyExpanded()]),
      );

      final expanded = tester.widget<Expanded>(find.byType(Expanded));
      expect(expanded.flex, 1);
    });

    testWidgets('flex 값을 지정하면 그대로 반영된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const Row(children: [EmptyExpanded(flex: 3)]),
      );

      final expanded = tester.widget<Expanded>(find.byType(Expanded));
      expect(expanded.flex, 3);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
