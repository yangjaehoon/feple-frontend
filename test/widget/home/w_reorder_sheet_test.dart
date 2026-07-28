import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<ReorderItem> items,
    String? subtitle,
    required void Function(List<int>) onSave,
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
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: ReorderSheet(
                title: '순서 변경',
                subtitle: subtitle,
                items: items,
                onSave: onSave,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ReorderSheet 렌더링', () {
    testWidgets('제목과 항목 목록을 보여준다', (tester) async {
      await pump(
        tester,
        items: const [
          ReorderItem(id: 1, name: '항목1'),
          ReorderItem(id: 2, name: '항목2'),
        ],
        onSave: (_) {},
      );

      expect(find.text('순서 변경'), findsOneWidget);
      expect(find.text('항목1'), findsOneWidget);
      expect(find.text('항목2'), findsOneWidget);
    });

    testWidgets('subtitle이 있으면 함께 보여준다', (tester) async {
      await pump(
        tester,
        items: const [ReorderItem(id: 1, name: '항목1')],
        subtitle: '드래그해서 순서를 바꾸세요',
        onSave: (_) {},
      );

      expect(find.text('드래그해서 순서를 바꾸세요'), findsOneWidget);
    });
  });

  group('ReorderSheet 확인', () {
    testWidgets('확인을 탭하면 현재 순서로 onSave가 호출되고 결과를 반환하며 닫힌다', (tester) async {
      List<int>? saved;
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      List<int>? popped;

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
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      popped = await Navigator.push<List<int>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReorderSheet(
                            title: '순서 변경',
                            items: const [
                              ReorderItem(id: 1, name: '항목1'),
                              ReorderItem(id: 2, name: '항목2'),
                            ],
                            onSave: (ids) => saved = ids,
                          ),
                        ),
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

      await tester.tap(find.widgetWithText(LoadingButton, 'confirm'.tr()));
      await tester.pumpAndSettle();

      expect(saved, [1, 2]);
      expect(popped, [1, 2]);
      expect(find.byType(ReorderSheet), findsNothing);
    });
  });
}
