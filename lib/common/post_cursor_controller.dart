import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/model/post_model.dart';
import 'package:flutter/widgets.dart';

/// 게시글 목록의 커서 페이지네이션 상태머신 (load/refresh/loadMore + 무한스크롤 트리거).
/// stale 응답 방지를 위해 각 요청에 [_loadId]를 매겨 최신 요청만 반영한다.
class PostCursorController extends SafeChangeNotifier {
  final Future<PostCursorPage> Function({int? cursor, int size}) fetchPage;
  final int pageSize;

  PostCursorController({required this.fetchPage, this.pageSize = 20});

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  Object? _error;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int? _nextCursor;
  int _loadId = 0;
  // refresh() 실패 시 설정 — UI가 snackbar로 표시 후 clearRefreshError() 호출 (일회성)
  String? _refreshError;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  Object? get error => _error;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get refreshError => _refreshError;

  void clearRefreshError() => _refreshError = null;

  Future<void> load() async {
    final myId = ++_loadId;
    // 진행 중이던 loadMore를 무효화 — 그 결과가 나중에 와도 _loadId 가드로 버려짐
    _isLoading = true;
    _hasError = false;
    _posts = [];
    _hasMore = true;
    _nextCursor = null;
    _isLoadingMore = false;
    safeNotify();
    try {
      final result = await fetchPage(size: pageSize);
      if (_loadId != myId) return;
      _posts = result.content;
      _hasMore = result.hasNext;
      _nextCursor = result.nextCursor;
      _isLoading = false;
      safeNotify();
    } catch (e) {
      if (_loadId != myId) return;
      _isLoading = false;
      _hasError = true;
      _error = e;
      safeNotify();
    }
  }

  Future<void> refresh() async {
    final myId = ++_loadId;
    if (_isLoadingMore) {
      _isLoadingMore = false;
      safeNotify();
    }
    try {
      final result = await fetchPage(size: pageSize);
      if (_loadId != myId) return;
      _posts = result.content;
      _hasMore = result.hasNext;
      _nextCursor = result.nextCursor;
      _hasError = false;
      safeNotify();
    } catch (e) {
      if (_loadId != myId) return;
      // 기존 목록은 유지하되(크래시 방지), 실패 사실은 알려야 한다 — 조용히 삼키면
      // 새로고침이 실제로 실패했는데도 사용자는 성공한 줄 알게 됨
      _refreshError = networkAwareErrorKey(e, 'err_fetch_data').tr();
      safeNotify();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    final myId = _loadId;
    _isLoadingMore = true;
    safeNotify();
    try {
      final result = await fetchPage(cursor: _nextCursor, size: pageSize);
      if (_loadId != myId) return;
      _posts = [..._posts, ...result.content];
      _hasMore = result.hasNext;
      _nextCursor = result.nextCursor;
      _isLoadingMore = false;
      safeNotify();
    } catch (_) {
      if (_loadId != myId) return;
      _isLoadingMore = false;
      safeNotify();
    }
  }

  void onScroll(ScrollController scrollController) {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent -
            AppDimens.loadMoreTriggerDistance) {
      loadMore();
    }
  }
}
