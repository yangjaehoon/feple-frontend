import 'package:feple/common/widget/w_tap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('Tap', () {
    testWidgets('탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await pumpCommonWidget(
        tester,
        Tap(onTap: () => tapped = true, child: const Text('탭영역')),
      );

      await tester.tap(find.text('탭영역'));
      expect(tapped, true);
    });

    testWidgets('길게 누르면 onLongPress가 호출된다', (tester) async {
      var longPressed = false;
      await pumpCommonWidget(
        tester,
        Tap(
          onTap: () {},
          onLongPress: () => longPressed = true,
          child: const Text('탭영역'),
        ),
      );

      await tester.longPress(find.text('탭영역'));
      expect(longPressed, true);
    });

    testWidgets('semanticsLabel을 지정하면 버튼 시맨틱스로 노출된다', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCommonWidget(
        tester,
        Tap(onTap: () {}, semanticsLabel: '좋아요', child: const Icon(Icons.favorite)),
      );

      final finder = find.bySemanticsLabel('좋아요');
      expect(finder, findsOneWidget);
      final data = tester.getSemantics(finder);
      expect(data.flagsCollection.isButton, true);
      handle.dispose();
    });

    testWidgets('semanticsLabel 미지정 시 시맨틱스 라벨이 없다', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCommonWidget(
        tester,
        Tap(onTap: () {}, child: const Icon(Icons.favorite)),
      );

      expect(find.bySemanticsLabel('좋아요'), findsNothing);
      handle.dispose();
    });
  });
}
