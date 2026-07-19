import 'package:feple/common/widget/w_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('Line', () {
    testWidgets('기본 height는 1이다', (tester) async {
      await pumpCommonWidget(tester, const Line());

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints, const BoxConstraints.tightFor(height: 1));
    });

    testWidgets('color와 height를 지정하면 그대로 반영된다', (tester) async {
      await pumpCommonWidget(tester, const Line(color: Colors.red, height: 4));

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, Colors.red);
      expect(container.constraints, const BoxConstraints.tightFor(height: 4));
    });

    testWidgets('margin을 지정하면 그대로 반영된다', (tester) async {
      const margin = EdgeInsets.symmetric(horizontal: 8);
      await pumpCommonWidget(tester, const Line(margin: margin));

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.margin, margin);
    });
  });
}
