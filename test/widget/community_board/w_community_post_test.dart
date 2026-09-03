import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_community_post.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}
class MockUserProvider extends Mock implements UserProvider {}

Post _post({int id = 1, String title = '게시글', int? userId = 5, String nickname = '작성자'}) =>
    Post(id: id, title: title, content: '내용', likeCount: 0, nickname: nickname, userId: userId);

Future<void> _pump(
  WidgetTester tester, {
  required String boardType,
  required String boardName,
  int? currentUserId = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final userProvider = MockUserProvider();
  when(() => userProvider.currentUserId).thenReturn(currentUserId);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: ChangeNotifierProvider<UserProvider>.value(
        value: userProvider,
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: CommunityPost(boardName: boardName, boardType: boardType),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// highlightKeyword가 검색어와 매치되면 RichText로 렌더링돼 find.text()로 못 찾으므로
/// 평문 텍스트를 찾는 용도의 헬퍼.
Finder _richText(String text) =>
    find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPostService mockPostService;

  setUp(() {
    mockPostService = MockPostService();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);
  });

  tearDown(() {
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
  });

  group('CommunityPost 비페이징 게시판(HOT)', () {
    testWidgets('로딩 후 게시글 목록을 보여주고 정렬/글쓰기 버튼이 없다', (tester) async {
      when(() => mockPostService.fetchPosts(BoardTypes.hot))
          .thenAnswer((_) async => [_post(title: '인기글1'), _post(id: 2, title: '인기글2')]);

      await _pump(tester, boardType: BoardTypes.hot, boardName: '인기 게시판');
      await tester.pumpAndSettle();

      expect(find.text('인기글1'), findsOneWidget);
      expect(find.text('인기글2'), findsOneWidget);
      expect(find.text('sort_latest'.tr()), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });
  });

  group('CommunityPost 페이징 게시판(FREE)', () {
    testWidgets('정렬 칩과 글쓰기 버튼이 보인다', (tester) async {
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판');
      await tester.pumpAndSettle();

      expect(find.text('sort_latest'.tr()), findsOneWidget);
      expect(find.text('sort_popular'.tr()), findsOneWidget);
    });

    testWidgets('인기순 칩을 탭하면 popular 정렬로 다시 조회한다', (tester) async {
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판');
      await tester.pumpAndSettle();

      await tester.tap(find.text('sort_popular'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: 'popular',
          )).called(1);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판');
      await tester.pumpAndSettle();

      expect(find.text('be_first_to_discuss'.tr(args: ['자유 게시판'])), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return PostCursorPage(content: [_post(title: '복구된글')], hasNext: false);
      });

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판');
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('복구된글'), findsOneWidget);
    });

    testWidgets('로그인하지 않고 글쓰기를 탭하면 안내 스낵바를 보여준다', (tester) async {
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판', currentUserId: null);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      expect(find.text('login_required'.tr()), findsOneWidget);
    });
  });

  group('CommunityPost 검색', () {
    testWidgets('검색어를 입력하면 디바운스 후 검색 결과를 보여준다', (tester) async {
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));
      when(() => mockPostService.searchInBoard('맛집', BoardTypes.free))
          .thenAnswer((_) async => [_post(title: '맛집 추천')]);

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '맛집');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(_richText('맛집 추천'), findsOneWidget);
    });

    testWidgets('검색어를 지우면 원래 목록으로 돌아온다', (tester) async {
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => PostCursorPage(content: [_post(title: '원래글')], hasNext: false));
      when(() => mockPostService.searchInBoard('맛집', BoardTypes.free))
          .thenAnswer((_) async => [_post(title: '맛집 추천')]);

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '맛집');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(_richText('맛집 추천'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('원래글'), findsOneWidget);
    });
  });

  group('CommunityPost 무한 스크롤', () {
    testWidgets('스크롤이 끝에 도달하면 다음 페이지를 불러온다', (tester) async {
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: null,
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => PostCursorPage(
            content: List.generate(20, (i) => _post(id: i, title: '글$i')),
            nextCursor: 20,
            hasNext: true,
          ));
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: 20,
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => PostCursorPage(
            content: [_post(id: 100, title: '추가로드글')],
            hasNext: false,
          ));

      await _pump(tester, boardType: BoardTypes.free, boardName: '자유 게시판');
      // 뷰포트가 넓으면 20개 항목이 화면에 다 들어가 스크롤 여지가 없으므로,
      // loadMore 트리거를 위해 뷰포트를 좁혀 스크롤이 발생하게 한다.
      tester.view.physicalSize = const Size(1080, 700);
      await tester.pumpAndSettle();

      // 큰 드래그 거리로 스크롤 끝까지 단번에 이동시켜 loadMore 트리거를 확실히 넘긴다
      await tester.drag(find.byType(ListView), const Offset(0, -100000));
      await tester.pumpAndSettle();

      verify(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: 20,
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).called(1);
    });
  });
}
