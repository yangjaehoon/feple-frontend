import 'package:feple/common/common.dart';
import 'package:feple/common/post_cursor_controller.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_write_post_fab.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/model/post_changed_event.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_list_row_skeleton.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/screen/main/tab/my_page/s_other_user_profile.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/model/post_model.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';

class CommunityPost extends StatefulWidget {
  final String boardName;
  final String boardType;

  const CommunityPost({
    super.key,
    required this.boardName,
    required this.boardType,
  });

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> with NavigationGuard {
  static const _pageSize = 20;
  static const _sortLatest = 'latest';
  static const _sortPopular = 'popular';

  final PostService _postService = sl<PostService>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late final _controller = PostCursorController(
    fetchPage: _fetchPage,
    pageSize: _pageSize,
  );

  String _sort = _sortLatest;
  bool _isSearching = false;
  List<Post>? _searchResults;
  bool _showScrollTop = false;
  Timer? _searchDebounce;
  // 응답이 늦게 도착했을 때 이미 지나간 키워드로 최신 결과를 덮어쓰지 않도록 가드
  // (onSubmitted가 디바운스를 우회해 즉시 호출되면서 이전 요청과 겹칠 수 있음)
  int _searchRequestId = 0;

  String get _serviceBoardType => widget.boardType;

  bool get _isPaginated => BoardTypes.isPaginated(_serviceBoardType);

  bool get _showWriteButton => BoardTypes.showWriteButton(_serviceBoardType);

  /// 비페이지네이션 게시판(hot 등)은 fetchPosts 결과를 hasNext:false인
  /// 1페이지짜리 PostCursorPage로 감싸 PostCursorController와 동일하게 다룬다.
  Future<PostCursorPage> _fetchPage({int? cursor, int size = 20}) async {
    if (_isPaginated) {
      return _postService.fetchPostsPage(
        _serviceBoardType,
        cursor: cursor,
        size: size,
        sort: _sort,
      );
    }
    final items = await _postService.fetchPosts(_serviceBoardType);
    return PostCursorPage(content: items, hasNext: false);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.load();
    _scrollController.addListener(_onScroll);
    AppEvents.postChanged.addListener(_onPostChanged);
  }

  @override
  void dispose() {
    AppEvents.postChanged.removeListener(_onPostChanged);
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    final refreshError = _controller.refreshError;
    if (refreshError != null) {
      _controller.clearRefreshError();
      context.showErrorSnackbar(refreshError);
    }
  }

  void _onPostChanged() {
    final event = AppEvents.postChanged.value;
    // refreshAll(null) 또는 현재 목록에 있는 게시글이 변경된 경우만 재로드.
    // load()가 아닌 refresh() 사용 — 이 화면을 보고 있지 않을 때도(IndexedStack
    // 백그라운드 탭) 전역 이벤트로 호출될 수 있어, 스켈레톤 플래시·스크롤 위치
    // 초기화 없이 조용히 최신화해야 함
    if (event?.postId == null ||
        _controller.posts.any((p) => p.id == event!.postId)) {
      _controller.refresh(silent: true);
    }
  }

  void _onScroll() {
    final pos = _scrollController.position;
    final showScrollTop = pos.pixels > AppDimens.scrollToTopThreshold;
    if (showScrollTop != _showScrollTop) {
      setState(() => _showScrollTop = showScrollTop);
    }
    _controller.onScroll(_scrollController);
  }

  Future<void> _openPost(Post post) async {
    await guardedNavigate(
      () => Navigator.of(context, rootNavigator: true).push(
        SlideRoute(
          builder: (_) =>
              PostDetailCard.fromPost(boardName: widget.boardName, post: post),
        ),
      ),
    );
  }

  void _scheduleSearch(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppDimens.animNormal, () => _search(keyword));
  }

  Future<void> _search(String keyword) async {
    final requestId = ++_searchRequestId;
    if (keyword.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _postService.searchInBoard(
        keyword.trim(),
        _serviceBoardType,
      );
      if (mounted && requestId == _searchRequestId) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('[CommunityPost] 검색 실패: $e');
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearching = false);
      }
    }
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: 8,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal,
          vertical: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 15),
                  SizedBox(height: 6),
                  SkeletonBox(width: 100, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const SkeletonBox(width: 60, height: 13),
          ],
        ),
      ),
      separatorBuilder: (_, _) =>
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
    );
  }

  Widget _buildList(AbstractThemeColors colors) {
    if (_isSearching && _searchResults == null) {
      return const ListRowSkeleton(showLeading: false);
    }
    if (_searchResults != null) {
      return _buildSearchResults(colors);
    }
    if (_controller.hasError) {
      return ErrorState.network(_controller.error!, onRetry: _controller.load);
    }
    if (_controller.posts.isEmpty) {
      return _buildEmptyState(colors);
    }
    return _buildPostListView(colors);
  }

  Widget _buildSearchResults(AbstractThemeColors colors) {
    if (_isSearching) {
      return const ListRowSkeleton(showLeading: false);
    }
    final displayPosts = _searchResults!;
    if (displayPosts.isEmpty) {
      return Center(
        child: Text(
          'no_search_results'.tr(),
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: displayPosts.length,
      itemBuilder: (context, index) {
        final post = displayPosts[index];
        return PostListTile(
          post: post,
          highlightKeyword: _searchController.text.trim(),
          onTap: () => _openPost(post),
          onAuthorTap: () => navigateToPostAuthor(
            context,
            userId: post.userId,
            nickname: post.nickname,
            profileImageUrl: post.profileImageUrl,
          ),
        );
      },
      separatorBuilder: (_, _) =>
          Divider(thickness: 1, color: colors.listDivider),
    );
  }

  Widget _buildEmptyState(AbstractThemeColors colors) {
    return RefreshableCenter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: colors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'be_first_to_discuss'.tr(args: [widget.boardName]),
              style: TextStyle(
                fontSize: AppDimens.fontSizeMd,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostListView(AbstractThemeColors colors) {
    final posts = _controller.posts;
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: posts.length + (_controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == posts.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: colors.activate),
            ),
          );
        }
        final post = posts[index];
        return AnimatedListItem(
          index: index,
          child: PostListTile(
            post: post,
            onTap: () => _openPost(post),
            onAuthorTap: () => navigateToPostAuthor(
              context,
              userId: post.userId,
              nickname: post.nickname,
              profileImageUrl: post.profileImageUrl,
            ),
          ),
        );
      },
      separatorBuilder: (_, _) =>
          Divider(thickness: 1, color: colors.listDivider),
    );
  }

  Widget _buildFab(AbstractThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showScrollTop) ...[
          FloatingActionButton.small(
            heroTag: 'scrollTop',
            onPressed: () => _scrollController.animateTo(
              0,
              duration: AppDimens.animNormal,
              curve: Curves.easeOut,
            ),
            backgroundColor: colors.surface,
            foregroundColor: colors.textTitle,
            elevation: 6,
            child: const Icon(Icons.arrow_upward_rounded, size: 20),
          ),
          const SizedBox(height: 8),
        ],
        if (_showWriteButton)
          WritePostFab(
            onPressed: () async {
              if (context.read<UserProvider>().currentUserId == null) {
                context.showInfoSnackbar('no_login_info'.tr());
                return;
              }
              await Navigator.push(
                context,
                SlideRoute(
                  builder: (_) => WritePost(
                    title: 'write_post'.tr(),
                    onSubmit:
                        (title, content, anonymous, imageObjectKey) async {
                          await _postService.createPost(
                            boardType: _serviceBoardType,
                            draft: PostDraft(
                              title: title,
                              content: content,
                              anonymous: anonymous,
                              imageObjectKey: imageObjectKey,
                            ),
                          );
                          AppEvents.postChanged.value =
                              PostChangedEvent.refreshAll();
                        },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchBar(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: StatefulBuilder(
        builder: (context, setSearchState) => TextField(
          controller: _searchController,
          onChanged: (v) {
            setSearchState(() {});
            _scheduleSearch(v);
          },
          onSubmitted: (v) {
            _searchDebounce?.cancel();
            _search(v);
          },
          style: TextStyle(
            color: colors.textTitle,
            fontSize: AppDimens.fontSizeMd,
          ),
          decoration: InputDecoration(
            hintText: 'search_posts_hint'.tr(),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: 'clear'.tr(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setSearchState(() {});
                      setState(() {
                        _searchResults = null;
                        _isSearching = false;
                      });
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SelectableChip(
            label: 'sort_latest'.tr(),
            selected: _sort == _sortLatest,
            margin: EdgeInsets.zero,
            onTap: () {
              setState(() => _sort = _sortLatest);
              _controller.load();
            },
          ),
          const SizedBox(width: 8),
          SelectableChip(
            label: 'sort_popular'.tr(),
            selected: _sort == _sortPopular,
            margin: EdgeInsets.zero,
            onTap: () {
              setState(() => _sort = _sortPopular);
              _controller.load();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      floatingActionButton: _buildFab(colors),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          SecondaryAppBar(title: widget.boardName),
          _buildSearchBar(colors),
          if (_isPaginated) _buildSortChips(),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _controller.refresh,
              child: _controller.isLoading
                  ? _buildSkeletonList()
                  : _buildList(colors),
            ),
          ),
        ],
      ),
    );
  }
}
