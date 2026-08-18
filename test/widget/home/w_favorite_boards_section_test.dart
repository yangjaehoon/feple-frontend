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

Future<void> _pump(
  WidgetTester tester, {
  List<FavoriteBoard> allBoards = const [],
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
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

    testWidgets('게시판이 없으면 선택 안내 문구를 보여주고 CTA는 없다', (tester) async {
      await _pump(tester, allBoards: []);
      await tester.pump();

      expect(find.text('select_boards_prompt'.tr()), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('게시판은 있지만 선택된 게 없으면 CTA 버튼을 보여준다', (tester) async {
      // 저장된 선택 ID가 실제 게시판 중 어느 것과도 일치하지 않아, 로드 시
      // selectedBoards가 빈 목록이 되는 상태(사용자가 전부 선택 해제한 경우)를 재현.
      await _pump(
        tester,
        allBoards: [_board()],
        prefsValues: {
          'fav_boards_1': ['nonexistent_board_id'],
        },
      );
      await tester.pump();

      expect(find.text('select_boards_prompt'.tr()), findsOneWidget);
      expect(find.text('favorite_boards_select_cta'.tr()), findsOneWidget);
    });

    testWidgets('CTA 버튼을 탭하면 전체 목록 화면으로 이동한다', (tester) async {
      await _pump(
        tester,
        allBoards: [_board()],
        prefsValues: {
          'fav_boards_1': ['nonexistent_board_id'],
        },
      );
      await tester.pump();

      await tester.tap(find.text('favorite_boards_select_cta'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(AllFavoriteBoardsScreen), findsOneWidget);
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
