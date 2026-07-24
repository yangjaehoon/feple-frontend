import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/login/w_password_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, String password) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: MaterialApp(home: Scaffold(body: PasswordChecklist(password: password))),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PasswordChecklist', () {
    testWidgets('빈 비밀번호면 모든 규칙이 미충족(회색/unchecked) 아이콘으로 표시된다', (tester) async {
      await _pump(tester, '');

      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('모든 규칙을 만족하는 비밀번호면 5개 모두 체크된다', (tester) async {
      await _pump(tester, 'Abcdef1!');

      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNothing);
    });

    testWidgets('길이만 충족하고 나머지 조건이 없으면 최소 길이 규칙만 체크된다', (tester) async {
      await _pump(tester, 'aaaaaaaa');

      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2)); // 길이 + 소문자
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(3));
    });

    testWidgets('대문자만 없으면 나머지 4개만 체크된다', (tester) async {
      await _pump(tester, 'abcdef1!');

      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(1));
    });
  });
}
