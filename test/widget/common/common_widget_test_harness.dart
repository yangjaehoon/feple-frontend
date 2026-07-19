import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 공용 위젯(lib/common/widget/*) 테스트용 셋업.
/// `.tr()`을 쓰는 위젯이 있어 EasyLocalization으로, `context.appColors`를 쓰는
/// 위젯이 있어 CustomThemeHolder로 감싼다.
Future<void> pumpCommonWidget(
  WidgetTester tester,
  Widget child, {
  CustomTheme theme = CustomTheme.light,
}) async {
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
        theme: theme,
        changeTheme: (_) {},
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    ),
  );
  await tester.pump();
}
