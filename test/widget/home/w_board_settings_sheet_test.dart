import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/home/w_board_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FavoriteBoard _board(String id, String name) => FavoriteBoard(
      boardId: id,
      type: FavoriteBoardType.artist,
      entityId: 1,
      entityName: name,
      entityNameEn: '',
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<FavoriteBoard> allBoards,
  required List<String> initialOrderedIds,
  required Set<String> initialCheckedIds,
  required void Function(List<String>) onSave,
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
            body: BoardSettingsSheet(
              allBoards: allBoards,
              initialOrderedIds: initialOrderedIds,
              initialCheckedIds: initialCheckedIds,
              onSave: onSave,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BoardSettingsSheet 렌더링', () {
    testWidgets('게시판 목록과 선택 개수를 보여준다', (tester) async {
      await _pump(
        tester,
        allBoards: [_board('a', '아티스트'), _board('b', '동행')],
        initialOrderedIds: ['a'],
        initialCheckedIds: {'a'},
        onSave: (_) {},
      );

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });
  });

  group('BoardSettingsSheet 선택', () {
    testWidgets('체크박스를 해제하면 선택 개수가 줄어든다', (tester) async {
      await _pump(
        tester,
        allBoards: [_board('a', '아티스트'), _board('b', '동행')],
        initialOrderedIds: ['a', 'b'],
        initialCheckedIds: {'a', 'b'},
        onSave: (_) {},
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(find.text('1/2'), findsOneWidget);
    });
  });

  group('BoardSettingsSheet 확인', () {
    testWidgets('확인을 탭하면 선택된 게시판 순서로 onSave가 호출되고 닫힌다', (tester) async {
      List<String>? saved;
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BoardSettingsSheet(
                          allBoards: [_board('a', '아티스트'), _board('b', '동행')],
                          initialOrderedIds: const ['a', 'b'],
                          initialCheckedIds: const {'a', 'b'},
                          onSave: (ids) => saved = ids,
                        ),
                      ),
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

      await tester.tap(find.widgetWithText(LoadingButton, 'confirm'.tr()));
      await tester.pumpAndSettle();

      expect(saved, ['a', 'b']);
      expect(find.byType(BoardSettingsSheet), findsNothing);
    });
  });
}
