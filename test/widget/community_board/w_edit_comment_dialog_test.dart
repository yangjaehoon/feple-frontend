import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/community_board/w_edit_comment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openDialog(WidgetTester tester, {String initialContent = '기존 댓글'}) async {
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
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (_) => EditCommentDialog(initialContent: initialContent),
                ),
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
}

void main() {
  group('EditCommentDialog 렌더링', () {
    testWidgets('기존 댓글 내용을 미리 채운다', (tester) async {
      await _openDialog(tester, initialContent: '기존 댓글');

      expect(find.text('기존 댓글'), findsOneWidget);
      expect(find.text('edit_comment'.tr()), findsOneWidget);
    });
  });

  group('EditCommentDialog 취소', () {
    testWidgets('취소를 탭하면 null을 반환하며 닫힌다', (tester) async {
      await _openDialog(tester);

      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(EditCommentDialog), findsNothing);
    });
  });

  group('EditCommentDialog 완료', () {
    testWidgets('내용을 수정하고 완료를 탭하면 수정된 텍스트를 반환한다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      String? result;
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
                      result = await showDialog<String>(
                        context: context,
                        builder: (_) => const EditCommentDialog(initialContent: '기존 댓글'),
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

      await tester.enterText(find.byType(TextField), '수정된 댓글');
      await tester.tap(find.text('done'.tr()));
      await tester.pumpAndSettle();

      expect(result, '수정된 댓글');
    });
  });

  group('EditCommentDialog 빈 내용 검증', () {
    testWidgets('내용을 비우고 완료를 탭하면 에러를 보여주고 닫히지 않는다', (tester) async {
      await _openDialog(tester);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('done'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('enter_comment_please'.tr()), findsOneWidget);
      expect(find.byType(EditCommentDialog), findsOneWidget);
    });

    testWidgets('에러가 보인 뒤 다시 입력하면 에러가 사라진다', (tester) async {
      await _openDialog(tester);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('done'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('enter_comment_please'.tr()), findsOneWidget);

      await tester.enterText(find.byType(TextField), '다시 입력');
      await tester.pumpAndSettle();

      expect(find.text('enter_comment_please'.tr()), findsNothing);
    });
  });
}
