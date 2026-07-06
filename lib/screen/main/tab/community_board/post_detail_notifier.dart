import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/service/comment_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PostDetailNotifier extends SafeChangeNotifier {
  final int postId;
  final _postService = sl<PostService>();
  final _commentService = sl<CommentService>();
  final _scrapService = sl<ScrapService>();

  // 댓글 내용이 바뀔 때만 증가 — UI에서 CommentSection만 구독할 수 있도록
  final ValueNotifier<int> commentsVersion = ValueNotifier(0);

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

  void _replaceCommentAt(int index, CommentDetail updated) {
    final newList = List<CommentDetail>.from(comments);
    newList[index] = updated;
    comments = newList;
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

  @override
  void dispose() {
    commentsVersion.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await Future.wait([loadPostState(), fetchComments(), _incrementView()]);
  }

  Future<void> _incrementView() async {
    viewCount++;
    safeNotify();
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
      safeNotify();
    } catch (e) {
      debugPrint('loadPostState error: $e');
    }
  }

  Future<void> fetchComments() async {
    try {
      comments = await _commentService.fetchPostComments(postId);
      commentsVersion.value++;
      safeNotify();
    } catch (e) {
      debugPrint('fetchComments error: $e');
    }
  }

  Future<void> submitComment(String content, {int? parentId, bool anonymous = false}) async {
    if (content.isEmpty) {
      commentError = 'enter_comment_please';
      safeNotify();
      return;
    }
    commentError = null;
    isSubmitting = true;
    safeNotify();

    try {
      await _commentService.submitComment(
        content: content,
        postId: postId,
        parentId: parentId,
        anonymous: anonymous,
      );
      await fetchComments();
      onSuccess?.call('comment_posted');
    } on BannedWordException {
      commentError = 'comment_banned_word';
      safeNotify();
    } catch (e) {
      debugPrint('submitComment error: $e');
      onError?.call(networkAwareErrorKey(e, 'comment_failed'));
    } finally {
      isSubmitting = false;
      safeNotify();
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
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      // 수정 다이얼로그가 열려있는 동안 댓글이 이미 삭제된 경우 —
      // 조용히 무시하면 사용자는 "완료"를 눌러도 반응이 없다고 오해함
      onError?.call('comment_update_failed');
      return;
    }
    final originalComment = comments[index];
    _replaceCommentAt(index, originalComment.copyWith(content: newContent, updatedAt: DateTime.now()));
    commentsVersion.value++;
    safeNotify();
    try {
      await _commentService.updateComment(commentId, newContent);
    } on BannedWordException {
      if (!isDisposed) {
        // await 도중 comments가 통째로 교체됐을 수 있으므로 캡처해둔 index가
        // 아니라 commentId로 다시 찾아서 롤백 (toggleCommentLike와 동일 패턴)
        final rollbackIndex = comments.indexWhere((c) => c.id == commentId);
        if (rollbackIndex != -1) _replaceCommentAt(rollbackIndex, originalComment);
        commentsVersion.value++;
        safeNotify();
      }
      // commentError는 하단 "새 댓글 작성" 입력창 전용 — 댓글 수정은 별도
      // 다이얼로그(이미 닫힌 상태)에서 일어나므로 스낵바로 알림
      onError?.call('comment_banned_word');
    } catch (e) {
      if (!isDisposed) {
        final rollbackIndex = comments.indexWhere((c) => c.id == commentId);
        if (rollbackIndex != -1) _replaceCommentAt(rollbackIndex, originalComment);
        commentsVersion.value++;
        safeNotify();
      }
      debugPrint('updateComment error: $e');
      onError?.call('comment_update_failed');
    }
  }

  Future<void> deleteComment(int commentId) async {
    // 부모 댓글을 지우면 그 답글들도 화면에서 함께 제거 — 부모 없는 답글이
    // 고아 상태로 남아 보이는 것을 막기 위함 (다른 mutator와 달리 단일 항목이
    // 아닌 이유). 서버 delete가 실패하면 아래 catch에서 답글까지 함께 복원됨
    final removed = comments.where((c) => c.id == commentId || c.parentId == commentId).toList();
    comments = comments
        .where((c) => c.id != commentId && c.parentId != commentId)
        .toList();
    commentsVersion.value++;
    safeNotify();
    try {
      await _commentService.deleteComment(commentId);
    } catch (e) {
      if (!isDisposed) {
        // 삭제 시도 전체를 스냅샷으로 되돌리면 대기 중 fetchComments()로 반영된
        // 다른 변경사항(예: 새 댓글)을 덮어쓸 수 있으므로, 삭제하려던 항목만
        // 현재 목록에 다시 합침
        final currentIds = comments.map((c) => c.id).toSet();
        comments = [...comments, ...removed.where((c) => !currentIds.contains(c.id))];
        commentsVersion.value++;
        safeNotify();
      }
      debugPrint('deleteComment error: $e');
      onError?.call('comment_delete_failed');
    }
  }

  // 댓글 하나의 좋아요만 바뀌므로 commentsVersion을 올리지 않는다 — 올리면
  // CommentSection 전체(모든 댓글 타일)가 다시 빌드된다. 대신 _LikeButton이
  // 로컬 optimistic 상태로 즉시 표시하고, 이 메서드는 성공 여부만 반환해
  // 실패 시 버튼 스스로 되돌리게 한다. comments 리스트 자체는 항상 갱신되므로
  // (다른 이유로) 전체가 재빌드될 때도 최신 상태가 반영된다.
  Future<bool> toggleCommentLike(int commentId, int? userId) async {
    if (userId == null) return false;
    if (_togglingCommentIds.contains(commentId)) return false;
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return false;
    final originalComment = comments[index];
    _togglingCommentIds.add(commentId);
    _replaceCommentAt(index, originalComment.copyWith(
      liked: !originalComment.liked,
      likeCount: originalComment.likeCount + (!originalComment.liked ? 1 : -1),
    ));
    try {
      await _commentService.toggleCommentLike(commentId);
      return true;
    } catch (e) {
      if (!isDisposed) {
        final commentIndex = comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          _replaceCommentAt(commentIndex, originalComment);
        }
      }
      debugPrint('toggleCommentLike error: $e');
      return false;
    } finally {
      _togglingCommentIds.remove(commentId);
    }
  }

  Future<void> toggleLike(int? userId) async {
    if (isToggling || userId == null) return;
    isToggling = true;
    HapticFeedback.lightImpact();
    try {
      await optimisticToggle(
        liked,
        apply: (v) { liked = v; heartCount += v ? 1 : -1; },
        action: () => _postService.toggleLike(postId),
        onError: () => onError?.call('like_failed'),
      );
    } finally {
      isToggling = false;
      safeNotify();
    }
  }

  Future<void> toggleScrap(int? userId) async {
    if (isScrapping || userId == null) return;
    isScrapping = true;
    HapticFeedback.lightImpact();
    try {
      await optimisticToggle(
        scraped,
        apply: (v) { scraped = v; scrapCount += v ? 1 : -1; },
        action: () => _scrapService.toggleScrap(postId),
        onSuccess: (v) => onSuccess?.call(v ? 'scrap_done' : 'scrap_cancel'),
        onError: () => onError?.call('scrap_failed'),
      );
    } finally {
      isScrapping = false;
      safeNotify();
    }
  }
}
