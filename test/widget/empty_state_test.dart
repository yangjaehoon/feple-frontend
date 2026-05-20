import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: Scaffold(body: child),
      ),
    );

void main() {
  group('EmptyState', () {
    testWidgets('title 텍스트 렌더링', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(icon: Icons.inbox, title: '항목 없음')),
      );

      expect(find.text('항목 없음'), findsOneWidget);
    });

    testWidgets('subtitle null이면 subtitle 텍스트 없음', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(icon: Icons.inbox, title: '항목 없음')),
      );

      // title만 있고 subtitle Text는 없어야 함
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('subtitle 있으면 렌더링', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(
          icon: Icons.inbox,
          title: '항목 없음',
          subtitle: '나중에 다시 시도하세요',
        )),
      );

      expect(find.text('항목 없음'), findsOneWidget);
      expect(find.text('나중에 다시 시도하세요'), findsOneWidget);
    });

    testWidgets('icon 렌더링', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(icon: Icons.search_off, title: '검색 결과 없음')),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });
}
