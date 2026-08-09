import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/comment_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/report_service.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}
class MockCommentService extends Mock implements CommentService {}
class MockScrapService extends Mock implements ScrapService {}
class MockReportService extends Mock implements ReportService {}
class MockBlockService extends Mock implements BlockService {}
class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockPostService mockPostService;
  late MockCommentService mockCommentService;
  late MockScrapService mockScrapService;
  late MockReportService mockReportService;
  late MockBlockService mockBlockService;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockPostService = MockPostService();
    mockCommentService = MockCommentService();
    mockScrapService = MockScrapService();
    mockReportService = MockReportService();
    mockBlockService = MockBlockService();

    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);
    if (sl.isRegistered<CommentService>()) sl.unregister<CommentService>();
    sl.registerSingleton<CommentService>(mockCommentService);
    if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();
    sl.registerSingleton<ScrapService>(mockScrapService);
    if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
    sl.registerSingleton<ReportService>(mockReportService);
    if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
    sl.registerSingleton<BlockService>(mockBlockService);

    when(() => mockPostService.fetchCounts(any()))
        .thenAnswer((_) async => (likeCount: 5, scrapCount: 2));
    when(() => mockPostService.isLiked(any())).thenAnswer((_) async => false);
    when(() => mockScrapService.isScraped(any())).thenAnswer((_) async => false);
    when(() => mockCommentService.fetchPostComments(any())).thenAnswer((_) async => <CommentDetail>[]);
    when(() => mockPostService.incrementPostView(any())).thenAnswer((_) async {});

    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(1);
  });

  tearDown(() {
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    if (sl.isRegistered<CommentService>()) sl.unregister<CommentService>();
    if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();
    if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
    if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
  });

  Widget wrap(Widget child) => EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        startLocale: const Locale('ko'),
        fallbackLocale: const Locale('ko'),
        path: 'assets/translations',
        useOnlyLangCode: true,
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (_) {},
            child: MaterialApp(home: child),
          ),
        ),
      );

  Future<void> pump(
    WidgetTester tester, {
    int postUserId = 1,
    String title = '제목',
    String content = '내용',
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(PostDetailCard(
      boardName: '자유 게시판',
      id: 10,
      nickname: '작성자',
      title: title,
      content: content,
      likeCount: 5,
      viewCount: 3,
      postUserId: postUserId,
    )));
    await tester.pump();
  }

  group('PostDetailCard 렌더링', () {
    testWidgets('제목, 내용, 좋아요/조회수를 보여준다', (tester) async {
      await pump(tester, title: '게시글 제목', content: '게시글 내용');
      await tester.pump();

      expect(find.text('게시글 제목'), findsOneWidget);
      expect(find.text('게시글 내용'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('PostDetailCard 메뉴', () {
    testWidgets('본인 글이면 수정/공유/삭제 메뉴를 보여준다', (tester) async {
      await pump(tester, postUserId: 1);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('edit_post'.tr()), findsOneWidget);
      expect(find.text('delete_post'.tr()), findsOneWidget);
      expect(find.text('share'.tr()), findsOneWidget);
    });

    testWidgets('타인 글이면 공유/신고/차단 메뉴를 보여준다', (tester) async {
      await pump(tester, postUserId: 999);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('report_post'.tr()), findsOneWidget);
      expect(find.text('block_user'.tr()), findsOneWidget);
      expect(find.text('edit_post'.tr()), findsNothing);
    });
  });

  group('PostDetailCard 삭제', () {
    testWidgets('삭제를 확인하면 deletePost 호출 후 화면이 닫힌다', (tester) async {
      when(() => mockPostService.deletePost(any())).thenAnswer((_) async {});

      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      await tester.pumpWidget(wrap(Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const PostDetailCard(
                  boardName: '자유 게시판',
                  id: 10,
                  nickname: '작성자',
                  title: '제목',
                  content: '내용',
                  likeCount: 0,
                  postUserId: 1,
                ),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      )));
      await tester.pump();
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('delete_post'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('delete_post_confirm'.tr()), findsOneWidget);
      await tester.tap(find.text('delete_post'.tr()).last);
      await tester.pumpAndSettle();

      verify(() => mockPostService.deletePost(10)).called(1);
      expect(find.byType(PostDetailCard), findsNothing);
    });
  });

  group('PostDetailCard 수정', () {
    testWidgets('수정을 탭하면 글쓰기 화면으로 이동한다', (tester) async {
      await pump(tester, postUserId: 1);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('edit_post'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(WritePost), findsOneWidget);
    });

    testWidgets('수정 성공 후 이미지 재조회 실패하면 안내 문구를 보여준다', (tester) async {
      when(() => mockPostService.updatePost(
            postId: any(named: 'postId'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            imageObjectKeys: any(named: 'imageObjectKeys'),
          )).thenAnswer((_) async {});
      when(() => mockPostService.fetchPost(10)).thenThrow(Exception('network'));

      await pump(tester, postUserId: 1);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('edit_post'.tr()));
      await tester.pumpAndSettle();

      // card_swiper 테스트와 동일한 이유(제스처 레이어 우회)로, 캡처한 WritePost의
      // onSubmit 콜백을 직접 호출해 수정 제출 로직을 검증한다.
      final writePost = tester.widget<WritePost>(find.byType(WritePost));
      await writePost.onSubmit('새 제목', '새 내용', false, const []);
      await tester.pump();

      expect(find.text('post_updated_image_refresh_failed'.tr()), findsOneWidget);
    });
  });

  group('PostDetailCard 신고', () {
    testWidgets('신고를 탭하면 신고 시트가 열린다', (tester) async {
      await pump(tester, postUserId: 999);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('report_post'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('report_post'.tr()), findsOneWidget);
    });
  });

  group('PostDetailCard 차단', () {
    testWidgets('차단을 탭하고 확인하면 blockUser가 호출된다', (tester) async {
      when(() => mockBlockService.blockUser(999)).thenAnswer((_) async {});

      await pump(tester, postUserId: 999);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('block_user'.tr()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('block'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockBlockService.blockUser(999)).called(1);
    });
  });

  group('PostDetailCard 댓글', () {
    testWidgets('로그인하지 않고 댓글을 제출하면 안내 스낵바를 보여준다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);

      await pump(tester);
      await tester.pump();

      await tester.enterText(find.byType(TextField), '댓글');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('no_login_info'.tr()), findsOneWidget);
    });

    testWidgets('로그인 상태로 댓글을 제출하면 submitComment가 호출된다', (tester) async {
      when(() => mockCommentService.submitComment(
            postId: any(named: 'postId'),
            content: any(named: 'content'),
            parentId: any(named: 'parentId'),
            anonymous: any(named: 'anonymous'),
          )).thenAnswer((_) async {});
      when(() => mockCommentService.fetchPostComments(10)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.enterText(find.byType(TextField), '댓글');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      verify(() => mockCommentService.submitComment(
            postId: 10,
            content: '댓글',
            parentId: null,
            anonymous: false,
          )).called(1);
    });
  });
}
