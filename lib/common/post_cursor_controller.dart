import 'package:dio/dio.dart' show CancelToken;
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/request_scope.dart';
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
  // stale 응답을 "무시"하는 가드. mock 기반 단위 테스트처럼 취소를 존중하지 않는
  // fetch 경로에서도 최신 요청만 반영되도록 유지한다.
  int _loadId = 0;
  // load/refresh 시 진행 중이던 실제 네트워크 요청을 중단해 낭비를 없앤다.
  CancelToken _fetchToken = CancelToken();
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
    // 진행 중이던 요청을 무효화(가드) + 실제로 중단(취소)
    _fetchToken.cancel();
    _fetchToken = CancelToken();
    final token = _fetchToken;
    _isLoading = true;
    _hasError = false;
    _posts = [];
    _hasMore = true;
    _nextCursor = null;
    _isLoadingMore = false;
    safeNotify();
    try {
      final result =
          await withCancelScope(token, () => fetchPage(size: pageSize));
      if (_loadId != myId) return;
      _posts = result.content;
      _hasMore = result.hasNext;
      _nextCursor = result.nextCursor;
      _isLoading = false;
      safeNotify();
    } catch (e) {
      if (isRequestCancelled(e) || _loadId != myId) return;
      _isLoading = false;
      _hasError = true;
      _error = e;
      safeNotify();
    }
  }

  /// [silent] true면 실패해도 [refreshError]를 설정하지 않음 — 화면이 보이지
  /// 않는 상태(백그라운드 탭)에서 전역 이벤트로 호출될 수 있는 새로고침용
  Future<void> refresh({bool silent = false}) async {
    final myId = ++_loadId;
    _fetchToken.cancel();
    _fetchToken = CancelToken();
    final token = _fetchToken;
    if (_isLoadingMore) {
      _isLoadingMore = false;
      safeNotify();
    }
    try {
      final result =
          await withCancelScope(token, () => fetchPage(size: pageSize));
      if (_loadId != myId) return;
      _posts = result.content;
      _hasMore = result.hasNext;
      _nextCursor = result.nextCursor;
      _hasError = false;
      safeNotify();
    } catch (e) {
      if (isRequestCancelled(e) || _loadId != myId) return;
      // 기존 목록은 유지하되(크래시 방지), 실패 사실은 알려야 한다 — 조용히 삼키면
      // 새로고침이 실제로 실패했는데도 사용자는 성공한 줄 알게 됨
      if (!silent) {
        _refreshError = fetchFailureText(e);
        safeNotify();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    final myId = _loadId;
    final token = _fetchToken;
    _isLoadingMore = true;
    safeNotify();
    try {
      final result = await withCancelScope(
        token,
        () => fetchPage(cursor: _nextCursor, size: pageSize),
      );
      if (_loadId != myId) return;
      _posts = [..._posts, ...result.content];
      _hasMore = result.hasNext;
      _nextCursor = result.nextCursor;
      _isLoadingMore = false;
      safeNotify();
    } catch (e) {
      if (isRequestCancelled(e) || _loadId != myId) return;
      _isLoadingMore = false;
      // 조용히 삼키면 "더 보기"가 실패했는데도 사용자는 그냥 목록이 끝난 줄 알게 됨
      _refreshError = fetchFailureText(e);
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

  @override
  void dispose() {
    _fetchToken.cancel();
    super.dispose();
  }
}
