import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/app_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAppAlertDialog', () {
    testWidgets('제목/본문/액션을 보여준다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => buildAppAlertDialog(
                  context,
                  title: '제목',
                  content: '내용',
                  actions: const [Text('확인')],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('제목'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });
  });
}
