import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/service/comment_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/foundation.dart';

class PostDetailNotifier extends ChangeNotifier {
  final int postId;
  final _postService = sl<PostService>();
  final _commentService = sl<CommentService>();
  final _scrapService = sl<ScrapService>();

  List<CommentDetail> comments = [];
  bool liked = false;
  bool scraped = false;
  late int heartCount;
  int scrapCount = 0;
  int viewCount = 0;
  bool isSubmitting = false;
  String? commentError;
  bool isToggling = false;
  bool isScrapping = false;
  final Set<int> _togglingCommentIds = {};
  bool _disposed = false;

  // comments 레퍼런스가 바뀔 때만 재계산되는 캐시
  List<CommentDetail>? _cachedComments;
  List<CommentDetail> _cachedRoots = const [];
  Map<int, List<CommentDetail>> _cachedRepliesMap = const {};

  List<CommentDetail> get rootComments {
    _recomputeIfNeeded();
    return _cachedRoots;
  }

  Map<int, List<CommentDetail>> get repliesMap {
    _recomputeIfNeeded();
    return _cachedRepliesMap;
  }

  void _recomputeIfNeeded() {
    if (identical(_cachedComments, comments)) return;
    _cachedRoots = comments.where((c) => c.parentId == null).toList();
    _cachedRepliesMap = {};
    for (final c in comments) {
      if (c.parentId != null) {
        _cachedRepliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }
    _cachedComments = comments;
  }

  void _replaceCommentAt(int idx, CommentDetail updated) {
    final newList = List<CommentDetail>.from(comments);
    newList[idx] = updated;
    comments = newList;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  final void Function(String)? onSuccess;
  final void Function(String)? onError;
  final void Function()? onPostDeleted;

  PostDetailNotifier({
    required this.postId,
    required int initialHeartCount,
    required int initialViewCount,
    this.onSuccess,
    this.onError,
    this.onPostDeleted,
  }) {
    heartCount = initialHeartCount;
    viewCount = initialViewCount;
  }

  Future<void> init() async {
    await Future.wait([loadPostState(), fetchComments(), _incrementView()]);
  }

  Future<void> _incrementView() async {
    viewCount++;
    _safeNotify();
    try {
      await _postService.incrementPostView(postId);
    } catch (e) {
      debugPrint('incrementView error: $e');
    }
  }

  Future<void> loadPostState() async {
    try {
      final (counts, isLiked, isScraped) = await (
        _postService.fetchCounts(postId),
        _postService.isLiked(postId),
        _scrapService.isScraped(postId),
      ).wait;
      liked = isLiked;
      scraped = isScraped;
      heartCount = counts.likeCount;
      scrapCount = counts.scrapCount;
      _safeNotify();
    } catch (e) {
      debugPrint('loadPostState error: $e');
    }
  }

  Future<void> fetchComments() async {
    try {
      comments = await _commentService.fetchPostComments(postId);
      _safeNotify();
    } catch (e) {
      debugPrint('fetchComments error: $e');
    }
  }

  Future<void> submitComment(String content, {int? parentId}) async {
    if (content.isEmpty) {
      commentError = 'enter_comment_please';
      _safeNotify();
      return;
    }
    commentError = null;
    isSubmitting = true;
    _safeNotify();

    try {
      await _commentService.submitComment(
        content: content,
        postId: postId,
        parentId: parentId,
      );
      await fetchComments();
      onSuccess?.call('comment_posted');
    } on BannedWordException {
      commentError = 'comment_banned_word';
      _safeNotify();
    } catch (e) {
      debugPrint('submitComment error: $e');
      onError?.call(networkAwareErrorKey(e, 'comment_failed'));
    } finally {
      isSubmitting = false;
      _safeNotify();
    }
  }

  Future<void> deletePost() async {
    try {
      await _postService.deletePost(postId);
      onPostDeleted?.call();
    } catch (e) {
      debugPrint('deletePost error: $e');
      onError?.call('post_delete_failed');
    }
  }

  Future<void> updateComment(int commentId, String newContent) async {
    final idx = comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final prev = comments[idx];
    _replaceCommentAt(idx, prev.copyWith(content: newContent, updatedAt: DateTime.now()));
    _safeNotify();
    try {
      await _commentService.updateComment(commentId, newContent);
    } on BannedWordException {
      _replaceCommentAt(idx, prev);
      commentError = 'comment_banned_word';
      _safeNotify();
    } catch (e) {
      _replaceCommentAt(idx, prev);
      _safeNotify();
      debugPrint('updateComment error: $e');
      onError?.call('comment_update_failed');
    }
  }

  Future<void> deleteComment(int commentId) async {
    final prev = List<CommentDetail>.from(comments);
    comments = comments
        .where((c) => c.id != commentId && c.parentId != commentId)
        .toList();
    _safeNotify();
    try {
      await _commentService.deleteComment(commentId);
    } catch (e) {
      comments = prev;
      _safeNotify();
      debugPrint('deleteComment error: $e');
      onError?.call('comment_delete_failed');
    }
  }

  Future<void> toggleCommentLike(int commentId, int? userId) async {
    if (userId == null) return;
    if (_togglingCommentIds.contains(commentId)) return;
    final idx = comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final prev = comments[idx];
    _togglingCommentIds.add(commentId);
    _replaceCommentAt(idx, prev.copyWith(
      liked: !prev.liked,
      likeCount: prev.likeCount + (!prev.liked ? 1 : -1),
    ));
    _safeNotify();
    try {
      final result = await _commentService.toggleCommentLike(commentId);
      // 서버 실제 값으로 동기화 — 빠른 연속 탭 시 불일치 방지
      final currentIdx = comments.indexWhere((c) => c.id == commentId);
      if (currentIdx != -1) {
        _replaceCommentAt(currentIdx, comments[currentIdx].copyWith(
          liked: result.liked,
          likeCount: result.likeCount,
        ));
        _safeNotify();
      }
    } catch (e) {
      final currentIdx = comments.indexWhere((c) => c.id == commentId);
      if (currentIdx != -1) {
        _replaceCommentAt(currentIdx, prev);
        _safeNotify();
      }
      debugPrint('toggleCommentLike error: $e');
    } finally {
      _togglingCommentIds.remove(commentId);
    }
  }

  Future<void> toggleLike(int? userId) async {
    if (isToggling || userId == null) return;
    isToggling = true;
    // 낙관적 업데이트 (TDA: 서버 응답을 물어서 결정하는 대신, 바로 토글 지시)
    final wasLiked = liked;
    liked = !liked;
    heartCount += liked ? 1 : -1;
    _safeNotify();
    try {
      await _postService.toggleLike(postId);
    } catch (e) {
      liked = wasLiked;
      heartCount += liked ? 1 : -1;
      debugPrint('toggleLike error: $e');
      onError?.call('like_failed');
    } finally {
      isToggling = false;
      _safeNotify();
    }
  }

  Future<void> toggleScrap(int? userId) async {
    if (isScrapping || userId == null) return;
    isScrapping = true;
    // 낙관적 업데이트 (TDA: 서버 응답 bool을 받아 결정하는 대신, 바로 토글 지시)
    final wasScraped = scraped;
    scraped = !scraped;
    scrapCount += scraped ? 1 : -1;
    _safeNotify();
    try {
      await _scrapService.toggleScrap(postId);
      onSuccess?.call(scraped ? 'scrap_done' : 'scrap_cancel');
    } catch (e) {
      scraped = wasScraped;
      scrapCount += wasScraped ? 1 : -1;
      debugPrint('toggleScrap error: $e');
      onError?.call('scrap_failed');
    } finally {
      isScrapping = false;
      _safeNotify();
    }
  }
}
