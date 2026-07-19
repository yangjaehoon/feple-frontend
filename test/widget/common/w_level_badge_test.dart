import 'package:feple/common/widget/w_level_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('LevelBadge', () {
    testWidgets('authorLevel이 null이면 빈 위젯을 렌더링한다', (tester) async {
      await pumpCommonWidget(tester, const LevelBadge(authorLevel: null));

      expect(find.byType(Tooltip), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('알 수 없는 레벨 문자열이면 빈 위젯을 렌더링한다', (tester) async {
      await pumpCommonWidget(tester, const LevelBadge(authorLevel: 'UNKNOWN'));

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('SEED 레벨이면 🌰 이모지를 렌더링한다', (tester) async {
      await pumpCommonWidget(tester, const LevelBadge(authorLevel: 'SEED'));

      expect(find.text('🌰'), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('LEGEND 레벨이면 👑 이모지를 렌더링한다', (tester) async {
      await pumpCommonWidget(tester, const LevelBadge(authorLevel: 'LEGEND'));

      expect(find.text('👑'), findsOneWidget);
    });

    testWidgets('fontSize를 지정하면 그대로 반영된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const LevelBadge(authorLevel: 'BLOOM', fontSize: 20),
      );

      final text = tester.widget<Text>(find.text('🌸'));
      expect(text.style?.fontSize, 20);
    });
  });
}
