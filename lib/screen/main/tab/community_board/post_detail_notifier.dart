import 'package:feple/injection.dart';
import 'package:feple/service/comment_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/foundation.dart';

class PostDetailNotifier extends ChangeNotifier {
  final int postId;
  final _postService = sl<PostService>();
  final _commentService = sl<CommentService>();
  final _scrapService = sl<ScrapService>();

  List<Map<String, dynamic>> comments = [];
  bool liked = false;
  bool scraped = false;
  late int heartCount;
  int scrapCount = 0;
  bool isSubmitting = false;
  String? commentError;
  bool isToggling = false;
  bool isScrapping = false;

  void Function(String)? onCommentPosted;
  void Function(String)? onError;

  PostDetailNotifier({required this.postId, required int initialHeartCount}) {
    heartCount = initialHeartCount;
  }

  Future<void> init() async {
    await Future.wait([loadPostState(), fetchComments()]);
  }

  Future<void> loadPostState() async {
    try {
      // 세 요청을 병렬 실행 (LoD: DioClient를 직접 알지 않음)
      final countsFuture = _postService.fetchCounts(postId);
      final likedFuture = _postService.isLiked(postId);
      final scrapedFuture = _scrapService.isScraped(postId);
      final counts = await countsFuture;
      liked = await likedFuture;
      scraped = await scrapedFuture;
      heartCount = counts.likeCount;
      scrapCount = counts.scrapCount;
      notifyListeners();
    } catch (e) {
      debugPrint('loadPostState error: $e');
    }
  }

  Future<void> fetchComments() async {
    try {
      comments = await _commentService.fetchPostComments(postId);
      notifyListeners();
    } catch (e) {
      debugPrint('fetchComments error: $e');
    }
  }

  Future<void> submitComment(String comment, int? userId, {int? parentId}) async {
    if (comment.isEmpty) {
      commentError = 'enter_comment_please';
      notifyListeners();
      return;
    }
    commentError = null;

    if (userId == null) {
      commentError = 'no_login_info';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      await _commentService.submitComment(
        content: comment,
        postId: postId,
        parentId: parentId,
      );
      await fetchComments();
      onCommentPosted?.call('comment_posted');
    } catch (e) {
      debugPrint('submitComment error: $e');
      onError?.call('comment_failed');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> toggleCommentLike(int commentId, int? userId) async {
    if (userId == null) return;
    try {
      final result = await _commentService.toggleCommentLike(commentId);
      final idx = comments.indexWhere((c) => c['id'] == commentId);
      if (idx != -1) {
        comments[idx] = Map<String, dynamic>.from(comments[idx])
          ..['liked'] = result.liked
          ..['likeCount'] = result.likeCount;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('toggleCommentLike error: $e');
    }
  }

  Future<void> toggleLike(int? userId) async {
    if (isToggling || userId == null) return;
    isToggling = true;
    // 낙관적 업데이트 (TDA: 서버 응답을 물어서 결정하는 대신, 바로 토글 지시)
    final wasLiked = liked;
    liked = !liked;
    heartCount += liked ? 1 : -1;
    notifyListeners();
    try {
      await _postService.toggleLike(postId);
    } catch (e) {
      liked = wasLiked;
      heartCount += liked ? 1 : -1;
      debugPrint('toggleLike error: $e');
      onError?.call('like_failed');
    } finally {
      isToggling = false;
      notifyListeners();
    }
  }

  Future<void> toggleScrap(int? userId) async {
    if (isScrapping || userId == null) return;
    isScrapping = true;
    // 낙관적 업데이트 (TDA: 서버 응답 bool을 받아 결정하는 대신, 바로 토글 지시)
    final wasScraped = scraped;
    scraped = !scraped;
    scrapCount += scraped ? 1 : -1;
    notifyListeners();
    try {
      await _scrapService.toggleScrap(postId);
      onCommentPosted?.call(scraped ? 'scrap_done' : 'scrap_cancel');
    } catch (e) {
      scraped = wasScraped;
      scrapCount += wasScraped ? 1 : -1;
      debugPrint('toggleScrap error: $e');
      onError?.call('scrap_failed');
    } finally {
      isScrapping = false;
      notifyListeners();
    }
  }
}
