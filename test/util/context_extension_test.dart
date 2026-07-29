import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/dart/extension/context_extension.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<BuildContext> pump(WidgetTester tester, {CustomTheme theme = CustomTheme.light}) async {
    late BuildContext captured;
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
          child: MaterialApp(
            home: Builder(builder: (context) {
              captured = context;
              return const SizedBox();
            }),
          ),
        ),
      ),
    );
    await tester.pump();
    return captured;
  }

  group('ContextExtension', () {
    testWidgets('appColors는 현재 테마의 색상을 반환한다', (tester) async {
      final context = await pump(tester, theme: CustomTheme.light);

      expect(context.appColors, isNotNull);
    });

    testWidgets('appShadows는 현재 테마의 그림자를 반환한다', (tester) async {
      final context = await pump(tester, theme: CustomTheme.light);

      expect(context.appShadows, isNotNull);
    });

    testWidgets('themeType은 현재 CustomTheme을 반환한다', (tester) async {
      final context = await pump(tester, theme: CustomTheme.dark);

      expect(context.themeType, CustomTheme.dark);
    });

    testWidgets('isEnglish는 로케일이 en일 때만 true', (tester) async {
      final context = await pump(tester);

      expect(context.isEnglish, isFalse);
    });

    testWidgets('changeTheme은 CustomThemeHolder의 콜백을 반환한다', (tester) async {
      CustomTheme? changedTo;
      late BuildContext captured;

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ko'), Locale('en')],
          startLocale: const Locale('ko'),
          fallbackLocale: const Locale('ko'),
          path: 'assets/translations',
          useOnlyLangCode: true,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (t) => changedTo = t,
            child: MaterialApp(
              home: Builder(builder: (context) {
                captured = context;
                return const SizedBox();
              }),
            ),
          ),
        ),
      );
      await tester.pump();

      captured.changeTheme(CustomTheme.dark);

      expect(changedTo, CustomTheme.dark);
    });
  });
}
