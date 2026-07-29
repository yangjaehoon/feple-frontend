import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/theme/theme_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    await EasyLocalization.ensureInitialized();
  });

  Future<BuildContext> pump(WidgetTester tester, {required CustomTheme theme, required void Function(CustomTheme) changeTheme}) async {
    late BuildContext captured;
    await tester.pumpWidget(
      CustomThemeHolder(
        theme: theme,
        changeTheme: changeTheme,
        child: MaterialApp(
          home: Builder(builder: (context) {
            captured = context;
            return const SizedBox();
          }),
        ),
      ),
    );
    await tester.pump();
    return captured;
  }

  group('ThemeUtil.changeTheme', () {
    testWidgets('선택한 테마를 저장하고 context.changeTheme을 호출한다', (tester) async {
      CustomTheme? changedTo;
      final context = await pump(
        tester,
        theme: CustomTheme.light,
        changeTheme: (t) => changedTo = t,
      );

      ThemeUtil.changeTheme(context, CustomTheme.dark);

      expect(changedTo, CustomTheme.dark);
      expect(Prefs.appTheme.get(), CustomTheme.dark);
    });
  });

  group('ThemeUtil.toggleTheme', () {
    testWidgets('light면 dark로 전환한다', (tester) async {
      CustomTheme? changedTo;
      final context = await pump(
        tester,
        theme: CustomTheme.light,
        changeTheme: (t) => changedTo = t,
      );

      ThemeUtil.toggleTheme(context);

      expect(changedTo, CustomTheme.dark);
    });

    testWidgets('dark면 light로 전환한다', (tester) async {
      CustomTheme? changedTo;
      final context = await pump(
        tester,
        theme: CustomTheme.dark,
        changeTheme: (t) => changedTo = t,
      );

      ThemeUtil.toggleTheme(context);

      expect(changedTo, CustomTheme.light);
    });
  });
}
