import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/home/favorite_board_navigation.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_post_list.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_board.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}

void main() {
  late MockPostService mockPostService;

  setUp(() {
    mockPostService = MockPostService();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);

    when(() => mockPostService.fetchArtistPostsPage(
          any(),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));
    when(() => mockPostService.fetchFestivalPostsPage(
          any(),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));
    when(() => mockPostService.fetchFestivalCompanionPostsPage(
          any(),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));
    when(() => mockPostService.fetchFestivalTicketPostsPage(
          any(),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));
  });

  tearDown(() {
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
  });

  Future<void> pump(WidgetTester tester, FavoriteBoard board) async {
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
                  onPressed: () => board.navigate(context),
                  child: const Text('이동'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FavoriteBoardNavigation.navigate', () {
    testWidgets('artist 타입이면 ArtistPostListScreen으로 이동한다', (tester) async {
      const board = FavoriteBoard(
        boardId: 'artist_1',
        type: FavoriteBoardType.artist,
        entityId: 1,
        entityName: '아티스트',
      );
      await pump(tester, board);

      await tester.tap(find.text('이동'));
      await tester.pumpAndSettle();

      expect(find.byType(ArtistPostListScreen), findsOneWidget);
    });

    testWidgets('festival 타입이면 FestivalBoardScreen으로 이동한다', (tester) async {
      const board = FavoriteBoard(
        boardId: 'festival_3',
        type: FavoriteBoardType.festival,
        entityId: 3,
        entityName: '페스티벌',
      );
      await pump(tester, board);

      await tester.tap(find.text('이동'));
      await tester.pumpAndSettle();

      expect(find.byType(FestivalBoardScreen), findsOneWidget);
    });
  });
}
