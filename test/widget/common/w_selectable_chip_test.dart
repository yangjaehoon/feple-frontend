import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  String label = '전체',
  bool selected = false,
  required VoidCallback onTap,
}) async {
  await tester.pumpWidget(
    CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(
        home: Scaffold(
          body: SelectableChip(label: label, selected: selected, onTap: onTap),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('SelectableChip 렌더링', () {
    testWidgets('라벨을 보여준다', (tester) async {
      await _pump(tester, label: '인기순', onTap: () {});

      expect(find.text('인기순'), findsOneWidget);
    });
  });

  group('SelectableChip 탭', () {
    testWidgets('탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(tester, onTap: () => tapped = true);

      await tester.tap(find.byType(SelectableChip));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
