import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_icon_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IconCircle 렌더링', () {
    testWidgets('아이콘을 보여준다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: IconCircle(icon: Icons.check_rounded)),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
