import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_status_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatusFilterChip 렌더링', () {
    testWidgets('라벨을 보여준다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: StatusFilterChip(
                label: '승인',
                selected: false,
                selectedColor: Colors.blue,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('승인'), findsOneWidget);
    });
  });

  group('StatusFilterChip 탭', () {
    testWidgets('탭하면 onSelected가 호출된다', (tester) async {
      bool? selectedValue;
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: StatusFilterChip(
                label: '승인',
                selected: false,
                selectedColor: Colors.blue,
                onSelected: (v) => selectedValue = v,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatusFilterChip));
      await tester.pump();

      expect(selectedValue, isTrue);
    });
  });

  group('StatusFilterChipRow 렌더링', () {
    testWidgets('전체 칩과 각 값의 칩을 보여준다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: StatusFilterChipRow<String>(
                values: const ['approved', 'pending'],
                selected: null,
                allLabel: '전체',
                labelOf: (v) => v == 'approved' ? '승인' : '대기',
                colorOf: (v, colors) => Colors.blue,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('전체'), findsOneWidget);
      expect(find.text('승인'), findsOneWidget);
      expect(find.text('대기'), findsOneWidget);
    });

    testWidgets('값 칩을 탭하면 onChanged가 호출된다', (tester) async {
      String? changed;
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: StatusFilterChipRow<String>(
                values: const ['approved'],
                selected: null,
                allLabel: '전체',
                labelOf: (v) => '승인',
                colorOf: (v, colors) => Colors.blue,
                onChanged: (v) => changed = v,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('승인'));
      await tester.pump();

      expect(changed, 'approved');
    });

    testWidgets('전체 칩을 탭하면 null로 onChanged가 호출된다', (tester) async {
      String? changed = 'approved';
      var changedCalled = false;
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: StatusFilterChipRow<String>(
                values: const ['approved'],
                selected: 'approved',
                allLabel: '전체',
                labelOf: (v) => '승인',
                colorOf: (v, colors) => Colors.blue,
                onChanged: (v) {
                  changed = v;
                  changedCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('전체'));
      await tester.pump();

      expect(changedCalled, isTrue);
      expect(changed, isNull);
    });
  });
}
