import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

const _style = TextStyle(fontSize: 14);

void main() {
  group('ExpandableText 넘치지 않는 경우', () {
    testWidgets('짧은 텍스트는 더보기 버튼 없이 그대로 렌더링된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const SizedBox(
          width: 300,
          child: ExpandableText(text: '짧은 텍스트', style: _style),
        ),
      );

      expect(find.text('짧은 텍스트'), findsOneWidget);
      expect(find.text('show_more'.tr()), findsNothing);
    });
  });

  group('ExpandableText 넘치는 경우', () {
    testWidgets('maxLines를 초과하면 더보기 버튼이 나타나고 탭하면 전체 텍스트가 보인다', (tester) async {
      final longText = List.generate(50, (i) => '아주 긴 텍스트 문장입니다 $i').join(' ');

      await pumpCommonWidget(
        tester,
        SingleChildScrollView(
          child: SizedBox(
            width: 100,
            child: ExpandableText(text: longText, style: _style, maxLines: 1),
          ),
        ),
      );

      expect(find.text('show_more'.tr()), findsOneWidget);

      final textBefore = tester.widget<Text>(find.text(longText));
      expect(textBefore.maxLines, 1);
      expect(textBefore.overflow, TextOverflow.ellipsis);

      await tester.tap(find.text('show_more'.tr()));
      await tester.pump();

      expect(find.text('show_less'.tr()), findsOneWidget);
      final textAfter = tester.widget<Text>(find.text(longText));
      expect(textAfter.maxLines, isNull);
      expect(textAfter.overflow, TextOverflow.visible);
    });
  });
}
