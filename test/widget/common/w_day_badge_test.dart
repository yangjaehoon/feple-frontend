import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/widget/w_day_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('DayBadge', () {
    testWidgets('dDays가 음수면 진행중 라벨을 보여준다', (tester) async {
      await pumpCommonWidget(tester, const DayBadge(dDays: -1));

      expect(find.text('festival_ongoing'.tr()), findsOneWidget);
    });

    testWidgets('dDays가 0이면 D-DAY 라벨을 보여준다', (tester) async {
      await pumpCommonWidget(tester, const DayBadge(dDays: 0));

      expect(find.text('d_day'.tr()), findsOneWidget);
    });

    testWidgets('dDays가 1~7이면 D-n 라벨과 activate 색을 사용한다', (tester) async {
      await pumpCommonWidget(tester, const DayBadge(dDays: 3));

      expect(find.text('D-3'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, CustomTheme.light.appColors.activate);
    });

    testWidgets('dDays가 7보다 크면 D-n 라벨과 textSecondary 색을 사용한다', (tester) async {
      await pumpCommonWidget(tester, const DayBadge(dDays: 10));

      expect(find.text('D-10'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, CustomTheme.light.appColors.textSecondary);
    });
  });
}
