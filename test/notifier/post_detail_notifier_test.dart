import 'package:feple/injection.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/screen/main/tab/community_board/post_detail_notifier.dart';
import 'package:feple/service/comment_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPostService extends Mock implements PostService {}
class MockCommentService extends Mock implements CommentService {}
class MockScrapService extends Mock implements ScrapService {}

CommentDetail _comment({int id = 1, int likeCount = 0, bool liked = false}) =>
    CommentDetail(
      id: id,
      postId: 1,
      userId: 10,
      nickname: 'user',
      content: '댓글',
      createdAt: DateTime(2025),
      certified: false,
      likeCount: likeCount,
      liked: liked,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPostService mockPostService;
  late MockCommentService mockCommentService;
  late MockScrapService mockScrapService;
  late PostDetailNotifier notifier;

  setUp(() {
    mockPostService = MockPostService();
    mockCommentService = MockCommentService();
    mockScrapService = MockScrapService();

    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    if (sl.isRegistered<CommentService>()) sl.unregister<CommentService>();
    if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();

    sl.registerSingleton<PostService>(mockPostService);
    sl.registerSingleton<CommentService>(mockCommentService);
    sl.registerSingleton<ScrapService>(mockScrapService);

    notifier = PostDetailNotifier(postId: 1, initialLikeCount: 10, initialViewCount: 0);
  });

  tearDown(() {
    sl.unregister<PostService>();
    sl.unregister<CommentService>();
    sl.unregister<ScrapService>();
  });

  group('fetchComments', () {
    test('성공 시 comments 목록 채움', () async {
      when(() => mockCommentService.fetchPostComments(1))
          .thenAnswer((_) async => [_comment(id: 1), _comment(id: 2)]);

      await notifier.fetchComments();

      expect(notifier.comments.length, 2);
    });

    test('서비스 예외 시 크래시 없이 comments 빈 상태 유지', () async {
      when(() => mockCommentService.fetchPostComments(1))
          .thenThrow(Exception('network'));

      await expectLater(notifier.fetchComments(), completes);

      expect(notifier.comments, isEmpty);
    });
  });

  group('submitComment', () {
    test('빈 댓글이면 commentError 설정, 서비스 미호출', () async {
      await notifier.submitComment('');

      expect(notifier.commentError, 'enter_comment_please');
      verifyNever(() => mockCommentService.submitComment(
          content: any(named: 'content'),
          postId: any(named: 'postId'),
          parentId: any(named: 'parentId')));
    });

    test('성공 시 comments 갱신, onSuccess 호출, isSubmitting false', () async {
      when(() => mockCommentService.submitComment(
            content: '내용',
            postId: 1,
            parentId: null,
          )).thenAnswer((_) async {});
      when(() => mockCommentService.fetchPostComments(1))
          .thenAnswer((_) async => [_comment()]);

      String? posted;
      final n = PostDetailNotifier(
        postId: 1, initialLikeCount: 10, initialViewCount: 0,
        onSuccess: (key) => posted = key,
      );
      await n.submitComment('내용');

      expect(posted, 'comment_posted');
      expect(n.comments.length, 1);
      expect(n.isSubmitting, false);
      n.dispose();
    });

    test('대댓글(parentId 지정) 성공 시 parentId 전달', () async {
      when(() => mockCommentService.submitComment(
            content: '대댓글',
            postId: 1,
            parentId: 42,
          )).thenAnswer((_) async {});
      when(() => mockCommentService.fetchPostComments(1))
          .thenAnswer((_) async => []);

      await notifier.submitComment('대댓글', parentId: 42);

      verify(() => mockCommentService.submitComment(
          content: '대댓글', postId: 1, parentId: 42)).called(1);
    });

    test('서비스 예외 시 onError 호출, isSubmitting false 복구', () async {
      when(() => mockCommentService.submitComment(
            content: '내용',
            postId: 1,
            parentId: null,
          )).thenThrow(Exception('err'));

      String? errorKey;
      final n = PostDetailNotifier(
        postId: 1, initialLikeCount: 10, initialViewCount: 0,
        onError: (key) => errorKey = key,
      );
      await n.submitComment('내용');

      expect(errorKey, 'comment_failed');
      expect(n.isSubmitting, false);
      n.dispose();
    });
  });

  group('toggleLike', () {
    test('userId null이면 서비스 미호출, 상태 변경 없음', () async {
      await notifier.toggleLike(null);

      verifyNever(() => mockPostService.toggleLike(any()));
      expect(notifier.liked, false);
    });

    test('isToggling 중 재호출 무시', () async {
      when(() => mockPostService.toggleLike(1)).thenAnswer((_) async {});

      final f1 = notifier.toggleLike(1);
      final f2 = notifier.toggleLike(1);
      await Future.wait([f1, f2]);

      verify(() => mockPostService.toggleLike(1)).called(1);
    });

    test('liked=false → true 낙관적 업데이트, likeCount+1', () async {
      when(() => mockPostService.toggleLike(1)).thenAnswer((_) async {});
      notifier.liked = false;
      notifier.likeCount = 10;

      await notifier.toggleLike(1);

      expect(notifier.liked, true);
      expect(notifier.likeCount, 11);
      expect(notifier.isToggling, false);
    });

    test('서비스 예외 시 liked·likeCount 롤백', () async {
      when(() => mockPostService.toggleLike(1)).thenThrow(Exception('err'));

      String? errorKey;
      final n = PostDetailNotifier(
        postId: 1, initialLikeCount: 10, initialViewCount: 0,
        onError: (key) => errorKey = key,
      );
      n.liked = false;

      await n.toggleLike(1);

      expect(n.liked, false);
      expect(n.likeCount, 10);
      expect(n.isToggling, false);
      expect(errorKey, 'like_failed');
      n.dispose();
    });
  });

  group('toggleScrap', () {
    test('userId null이면 서비스 미호출', () async {
      await notifier.toggleScrap(null);

      verifyNever(() => mockScrapService.toggleScrap(any()));
    });

    test('isScrapping 중 재호출 무시', () async {
      when(() => mockScrapService.toggleScrap(1)).thenAnswer((_) async {});

      final f1 = notifier.toggleScrap(1);
      final f2 = notifier.toggleScrap(1);
      await Future.wait([f1, f2]);

      verify(() => mockScrapService.toggleScrap(1)).called(1);
    });

    test('scraped=false → true 낙관적 업데이트, scrapCount+1', () async {
      when(() => mockScrapService.toggleScrap(1)).thenAnswer((_) async {});
      notifier.scraped = false;
      notifier.scrapCount = 5;

      await notifier.toggleScrap(1);

      expect(notifier.scraped, true);
      expect(notifier.scrapCount, 6);
      expect(notifier.isScrapping, false);
    });

    test('서비스 예외 시 scraped·scrapCount 롤백', () async {
      when(() => mockScrapService.toggleScrap(1)).thenThrow(Exception('err'));

      String? errorKey;
      final n = PostDetailNotifier(
        postId: 1, initialLikeCount: 10, initialViewCount: 0,
        onError: (key) => errorKey = key,
      );
      n.scraped = false;
      n.scrapCount = 5;

      await n.toggleScrap(1);

      expect(n.scraped, false);
      expect(n.scrapCount, 5);
      expect(n.isScrapping, false);
      expect(errorKey, 'scrap_failed');
      n.dispose();
    });
  });

  group('toggleCommentLike', () {
    test('userId null이면 서비스 미호출', () async {
      await notifier.toggleCommentLike(1, null);

      verifyNever(() => mockCommentService.toggleCommentLike(any()));
    });

    test('commentId가 comments에 없으면 상태 변경 없음', () async {
      when(() => mockCommentService.toggleCommentLike(99))
          .thenAnswer((_) async => (liked: true, likeCount: 1));
      notifier.comments = [_comment(id: 1, liked: false)];

      await notifier.toggleCommentLike(99, 10);

      expect(notifier.comments.first.liked, false);
    });

    test('성공 시 해당 댓글 liked·likeCount 갱신', () async {
      when(() => mockCommentService.toggleCommentLike(1))
          .thenAnswer((_) async => (liked: true, likeCount: 5));
      notifier.comments = [_comment(id: 1, likeCount: 4, liked: false)];

      await notifier.toggleCommentLike(1, 10);

      expect(notifier.comments.first.liked, true);
      expect(notifier.comments.first.likeCount, 5);
    });

    test('서비스 예외 시 크래시 없이 상태 유지', () async {
      when(() => mockCommentService.toggleCommentLike(1))
          .thenThrow(Exception('err'));
      notifier.comments = [_comment(id: 1, liked: false)];

      await expectLater(notifier.toggleCommentLike(1, 10), completes);

      expect(notifier.comments.first.liked, false);
    });
  });
}
