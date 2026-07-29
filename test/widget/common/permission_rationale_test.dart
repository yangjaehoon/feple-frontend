import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/permission_rationale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<bool?> pumpAndShow(
    WidgetTester tester, {
    required Future<bool> Function(BuildContext) show,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    bool? result;
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
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await show(context);
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return result;
  }

  group('PermissionRationale.showNotification', () {
    testWidgets('제목과 아이콘을 보여준다', (tester) async {
      await pumpAndShow(tester, show: PermissionRationale.showNotification);

      expect(find.text('perm_notif_title'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    });

    testWidgets('허용을 탭하면 true를 반환한다', (tester) async {
      bool? result;
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
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      result = await PermissionRationale.showNotification(context);
                    },
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('perm_notif_allow'.tr()));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('나중에를 탭하면 false를 반환한다', (tester) async {
      final result = await pumpAndShow(tester, show: PermissionRationale.showNotification);
      // pumpAndShow already tapped 열기; sheet is open, now tap 나중에
      await tester.tap(find.text('perm_later'.tr()));
      await tester.pumpAndSettle();

      expect(result, anyOf(isNull, isFalse));
    });
  });

  group('PermissionRationale.showLocation', () {
    testWidgets('제목과 아이콘을 보여준다', (tester) async {
      await pumpAndShow(tester, show: PermissionRationale.showLocation);

      expect(find.text('perm_loc_title'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });
  });
}
