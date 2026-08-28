import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_section.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_post_list.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_board.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}

Post _post({int id = 1, String title = '글'}) =>
    Post(id: id, title: title, content: '내용', likeCount: 0, nickname: '작성자');

void main() {
  late MockPostService mockPostService;

  setUp(() {
    mockPostService = MockPostService();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);
  });

  tearDown(() {
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
  });

  Future<void> pump(WidgetTester tester) async {
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
              body: ArtistBoard(artistId: 1, artistName: '아티스트'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ArtistBoard 렌더링', () {
    testWidgets('아티스트 게시글을 불러와 보여준다', (tester) async {
      when(() => mockPostService.fetchArtistPosts(1))
          .thenAnswer((_) async => [_post(title: '아티스트 인기글')]);

      await pump(tester);
      await tester.pump();

      expect(find.text('아티스트 인기글'), findsOneWidget);
    });
  });

  group('ArtistBoard 네비게이션', () {
    testWidgets('헤더를 탭하면 아티스트 게시판 전체 목록으로 이동한다', (tester) async {
      when(() => mockPostService.fetchArtistPosts(1)).thenAnswer((_) async => []);
      when(() => mockPostService.fetchArtistPostsPage(
            1,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('name_board'.tr(args: ['아티스트'])));
      await tester.pumpAndSettle();

      expect(find.byType(ArtistPostListScreen), findsOneWidget);
    });
  });

  group('ArtistBoard 새로고침', () {
    testWidgets('boardKey로 refresh를 호출하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockPostService.fetchArtistPosts(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });
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
                body: ArtistBoard(artistId: 1, artistName: '아티스트'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(callCount, 1);

      await tester
          .state<BoardPreviewSectionState>(find.byType(BoardPreviewSection))
          .refreshSection();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
