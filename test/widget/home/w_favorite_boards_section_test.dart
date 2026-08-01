import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/home/s_all_favorite_boards.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FavoriteBoard _board({String boardId = 'artist_1', String name = '아티스트게시판'}) =>
    FavoriteBoard(
      boardId: boardId,
      type: FavoriteBoardType.artist,
      entityId: 1,
      entityName: name,
      entityNameEn: '',
    );

Future<void> _pump(WidgetTester tester, {List<FavoriteBoard> allBoards = const []}) async {
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
            body: FavoriteBoardsSection(allBoards: allBoards, userId: 1),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('FavoriteBoardsSection 렌더링', () {
    testWidgets('저장된 선택이 없으면 전체 게시판을 보여준다', (tester) async {
      await _pump(tester, allBoards: [_board(name: '아티스트')]);
      await tester.pump();

      expect(find.text('favorite_board_name'.tr(args: ['아티스트'])), findsOneWidget);
      expect(find.text('favorite_boards'.tr()), findsOneWidget);
    });

    testWidgets('게시판이 없으면 선택 안내 문구를 보여준다', (tester) async {
      await _pump(tester, allBoards: []);
      await tester.pump();

      expect(find.text('select_boards_prompt'.tr()), findsOneWidget);
    });
  });

  group('FavoriteBoardsSection 전체보기', () {
    testWidgets('게시판이 있으면 더보기 화살표로 전체 목록에 진입한다', (tester) async {
      await _pump(tester, allBoards: [_board()]);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AllFavoriteBoardsScreen), findsOneWidget);
    });

    testWidgets('게시판이 없으면 더보기 화살표가 없다', (tester) async {
      await _pump(tester, allBoards: []);
      await tester.pump();

      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
    });
  });
}
