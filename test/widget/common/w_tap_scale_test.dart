import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TapScale 렌더링', () {
    testWidgets('child를 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TapScale(onTap: () {}, child: const Text('내용')),
          ),
        ),
      );

      expect(find.text('내용'), findsOneWidget);
    });
  });

  group('TapScale 탭', () {
    testWidgets('탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TapScale(onTap: () => tapped = true, child: const Text('내용')),
          ),
        ),
      );

      await tester.tap(find.byType(TapScale));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('TapScale 접근성', () {
    testWidgets('semanticsLabel을 지정하면 Semantics에 반영된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TapScale(
              onTap: () {},
              semanticsLabel: '설명',
              child: const Text('내용'),
            ),
          ),
        ),
      );

      // Semantics 라벨은 자식(child)의 텍스트와 병합되므로 포함 여부로 확인한다.
      final semantics = tester.getSemantics(find.byType(TapScale));
      expect(semantics.label, contains('설명'));
    });
  });
}
