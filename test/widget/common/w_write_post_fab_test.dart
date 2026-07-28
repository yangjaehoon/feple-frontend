import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_write_post_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required VoidCallback onPressed}) async {
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
          child: MaterialApp(
            home: Scaffold(floatingActionButton: WritePostFab(onPressed: onPressed)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('WritePostFab 렌더링', () {
    testWidgets('글쓰기 라벨과 아이콘을 보여준다', (tester) async {
      await pump(tester, onPressed: () {});

      expect(find.text('write_post'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });
  });

  group('WritePostFab 탭', () {
    testWidgets('탭하면 onPressed가 호출된다', (tester) async {
      var tapped = false;
      await pump(tester, onPressed: () => tapped = true);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
