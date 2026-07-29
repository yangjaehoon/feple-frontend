import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/dart/extension/context_extension.dart';
import 'package:feple/common/util/popup_menu_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpMenu(WidgetTester tester, {required bool danger}) async {
    await tester.pumpWidget(
      CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => PopupMenuButton<String>(
                itemBuilder: (context) => [
                  buildPopupMenuItem<String>(
                    value: 'delete',
                    icon: Icons.delete,
                    label: '삭제',
                    colors: context.appColors,
                    danger: danger,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
  }

  group('buildPopupMenuItem', () {
    testWidgets('아이콘과 라벨을 보여준다', (tester) async {
      await pumpMenu(tester, danger: false);

      expect(find.text('삭제'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('danger가 true면 error 색상을 사용한다', (tester) async {
      await pumpMenu(tester, danger: true);

      final icon = tester.widget<Icon>(find.byIcon(Icons.delete));
      expect(icon.color, isNotNull);
    });
  });
}
