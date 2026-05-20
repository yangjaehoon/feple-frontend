import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
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
  group('AppTextField', () {
    testWidgets('errorText null이면 TextField 렌더링, 에러 텍스트 없음', (tester) async {
      await tester.pumpWidget(_wrap(
        AppTextField(
          controller: TextEditingController(),
          hintText: '입력',
          icon: Icons.email,
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('에러 발생'), findsNothing);
    });

    testWidgets('errorText 있으면 에러 텍스트 렌더링', (tester) async {
      await tester.pumpWidget(_wrap(
        AppTextField(
          controller: TextEditingController(),
          hintText: '입력',
          icon: Icons.email,
          errorText: '에러 발생',
        ),
      ));

      expect(find.text('에러 발생'), findsOneWidget);
    });

    testWidgets('errorText 변경 시 새 텍스트로 갱신', (tester) async {
      await tester.pumpWidget(_wrap(
        AppTextField(
          controller: TextEditingController(),
          hintText: '입력',
          icon: Icons.email,
          errorText: '처음 에러',
        ),
      ));

      expect(find.text('처음 에러'), findsOneWidget);

      await tester.pumpWidget(_wrap(
        AppTextField(
          controller: TextEditingController(),
          hintText: '입력',
          icon: Icons.email,
          errorText: '바뀐 에러',
        ),
      ));

      expect(find.text('바뀐 에러'), findsOneWidget);
      expect(find.text('처음 에러'), findsNothing);
    });

    testWidgets('obscureText=true면 TextField에 반영', (tester) async {
      await tester.pumpWidget(_wrap(
        AppTextField(
          controller: TextEditingController(),
          hintText: '비밀번호',
          icon: Icons.lock,
          obscureText: true,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('onChanged 콜백 호출', (tester) async {
      String? changed;
      await tester.pumpWidget(_wrap(
        AppTextField(
          controller: TextEditingController(),
          hintText: '입력',
          icon: Icons.text_fields,
          onChanged: (v) => changed = v,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'hello');
      expect(changed, 'hello');
    });
  });
}
