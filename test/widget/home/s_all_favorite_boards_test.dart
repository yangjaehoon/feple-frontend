import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/home/s_all_favorite_boards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FavoriteBoard _artistBoard({String id = 'artist_1', String name = '아티스트'}) =>
    FavoriteBoard(boardId: id, type: FavoriteBoardType.artist, entityId: 1, entityName: name);

FavoriteBoard _festivalBoard({String id = 'festival_1', String name = '축제'}) =>
    FavoriteBoard(boardId: id, type: FavoriteBoardType.festival, entityId: 1, entityName: name);

Future<void> _pump(
  WidgetTester tester, {
  required List<FavoriteBoard> allBoards,
  required List<String> orderedSelectedIds,
  void Function(List<String>)? onSave,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
          home: AllFavoriteBoardsScreen(
            allBoards: allBoards,
            orderedSelectedIds: orderedSelectedIds,
            onSave: onSave ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('AllFavoriteBoardsScreen 렌더링', () {
    testWidgets('선택된 게시판이 없으면 안내 문구를 보여준다', (tester) async {
      await _pump(
        tester,
        allBoards: [_artistBoard()],
        orderedSelectedIds: const [],
      );

      expect(find.text('select_boards_prompt'.tr()), findsOneWidget);
    });

    testWidgets('선택된 게시판이 있으면 이름 오버레이와 함께 렌더링된다', (tester) async {
      await _pump(
        tester,
        allBoards: [_artistBoard(name: '아이유')],
        orderedSelectedIds: const ['artist_1'],
      );

      expect(find.text('favorite_board_name'.tr(args: ['아이유'])), findsOneWidget);
    });

    testWidgets('아티스트/축제 게시판이 섞여있으면 타입 필터 칩이 보인다', (tester) async {
      await _pump(
        tester,
        allBoards: [_artistBoard(), _festivalBoard()],
        orderedSelectedIds: const ['artist_1', 'festival_1'],
      );

      expect(find.text('filter_all'.tr()), findsOneWidget);
      expect(find.text('artist_boards_section'.tr()), findsOneWidget);
      expect(find.text('festival_boards_section'.tr()), findsOneWidget);
    });

    testWidgets('한 타입만 있으면 필터 칩이 보이지 않는다', (tester) async {
      await _pump(
        tester,
        allBoards: [_artistBoard()],
        orderedSelectedIds: const ['artist_1'],
      );

      expect(find.text('filter_all'.tr()), findsNothing);
    });
  });

  group('AllFavoriteBoardsScreen 필터', () {
    testWidgets('타입 필터를 선택하면 해당 타입만 표시된다', (tester) async {
      await _pump(
        tester,
        allBoards: [_artistBoard(name: '아이유'), _festivalBoard(name: '서울재즈')],
        orderedSelectedIds: const ['artist_1', 'festival_1'],
      );

      expect(find.byKey(const ValueKey('artist_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('festival_1')), findsOneWidget);

      await tester.tap(find.text('artist_boards_section'.tr()));
      await tester.pump();

      expect(find.byKey(const ValueKey('artist_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('festival_1')), findsNothing);
    });
  });

  group('AllFavoriteBoardsScreen 설정', () {
    testWidgets('설정 버튼을 탭하면 BoardSettingsSheet가 열린다', (tester) async {
      await _pump(
        tester,
        allBoards: [_artistBoard()],
        orderedSelectedIds: const ['artist_1'],
      );

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('select_boards'.tr()), findsOneWidget);
    });
  });
}
