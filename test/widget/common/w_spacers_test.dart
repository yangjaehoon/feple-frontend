import 'package:feple/common/widget/w_spacers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Height', () {
    testWidgets('지정한 높이의 SizedBox를 렌더링한다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Height(20)));

      final box = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(box.height, 20);
      expect(box.width, isNull);
    });

    test('height10/height5 상수는 지정한 값을 갖는다', () {
      expect(height10.height, 10);
      expect(height5.height, 5);
    });
  });

  group('Width', () {
    testWidgets('지정한 너비의 SizedBox를 렌더링한다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Width(20)));

      final box = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(box.width, 20);
      expect(box.height, isNull);
    });

    test('width10/width5 상수는 지정한 값을 갖는다', () {
      expect(width10.width, 10);
      expect(width5.width, 5);
    });
  });
}
