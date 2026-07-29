import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<bool?> pumpAndShow(WidgetTester tester) async {
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
                    result = await showConfirmDialog(
                      context,
                      title: '삭제하시겠습니까?',
                      content: '되돌릴 수 없습니다',
                      confirmLabel: '삭제',
                    );
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

  group('showConfirmDialog', () {
    testWidgets('제목/본문/확인 라벨을 보여준다', (tester) async {
      await pumpAndShow(tester);

      expect(find.text('삭제하시겠습니까?'), findsOneWidget);
      expect(find.text('되돌릴 수 없습니다'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('취소를 탭하면 false를 반환한다', (tester) async {
      await pumpAndShow(tester);

      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('확인을 탭하면 true를 반환한다', (tester) async {
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
                      result = await showConfirmDialog(
                        context,
                        title: '삭제하시겠습니까?',
                        content: '되돌릴 수 없습니다',
                        confirmLabel: '삭제',
                      );
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

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
