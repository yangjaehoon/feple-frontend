import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_write_post_fab.dart';
import 'package:feple/common/widget/w_write_post_screen.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/model/post_model.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';

class CommunityPost extends StatefulWidget {
  final String boardname;
  final String boardType;

  const CommunityPost({super.key, required this.boardname, required this.boardType});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  static const _pageSize = 20;
  static const _sortLatest = 'latest';
  static const _sortPopular = 'popular';

  final PostService _postService = sl<PostService>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Post> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;
  int? _cursor;
  int _loadId = 0;
  String _sort = _sortLatest;
  bool _isSearching = false;
  List<Post>? _searchResults;
  bool _showScrollTop = false;
  Timer? _searchDebounce;

  String get _serviceBoardType => widget.boardType;

  bool get _isPaginated => BoardTypes.isPaginated(_serviceBoardType);

  bool get _showWriteButton => BoardTypes.showWriteButton(_serviceBoardType);

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    final showTop = pos.pixels > 300;
    if (showTop != _showScrollTop) setState(() => _showScrollTop = showTop);
    if (_loadingMore || !_hasMore || !_isPaginated) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    final myId = ++_loadId;
    setState(() { _loading = true; _hasError = false; _posts.clear(); _cursor = null; _hasMore = true; });
    try {
      if (_isPaginated) {
        final page = await _postService.fetchPostsPage(_serviceBoardType, cursor: null, size: _pageSize, sort: _sort);
        if (!mounted || _loadId != myId) return;
        setState(() {
          _posts.addAll(page.content);
          _cursor = page.nextCursor;
          _hasMore = page.hasNext;
          _loading = false;
        });
      } else {
        final items = await _postService.fetchPosts(_serviceBoardType);
        if (!mounted || _loadId != myId) return;
        setState(() { _posts.addAll(items); _loading = false; });
      }
    } catch (e) {
      debugPrint('[CommunityPost] 게시글 로드 실패: $e');
      if (mounted && _loadId == myId) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _postService.fetchPostsPage(_serviceBoardType, cursor: _cursor, size: _pageSize, sort: _sort);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.content);
        _cursor = page.nextCursor;
        _hasMore = page.hasNext;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('[CommunityPost] 추가 로드 실패: $e');
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _scheduleSearch(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () => _search(keyword));
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _postService.searchInBoard(keyword.trim(), _serviceBoardType);
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      debugPrint('[CommunityPost] 검색 실패: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingHorizontal, vertical: 10),
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
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
    );
  }

  Widget _buildList(AbstractThemeColors colors) {
    if (_isSearching && _searchResults == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final displayPosts = _searchResults;
    if (displayPosts != null) {
      if (_isSearching) return const Center(child: CircularProgressIndicator());
      if (displayPosts.isEmpty) {
        return Center(
          child: Text('no_search_results'.tr(), style: TextStyle(color: colors.textSecondary)),
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
            onTap: () async {
              await Navigator.of(context, rootNavigator: true).push(
                SlideRoute(builder: (_) => EnlargePost.fromPost(boardname: widget.boardname, post: post)),
              );
              _load();
            },
          );
        },
        separatorBuilder: (_, __) => Divider(thickness: 1, color: colors.listDivider),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('err_fetch_data'.tr(args: ['']), style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('retry'.tr()),
              style: FilledButton.styleFrom(backgroundColor: colors.activate),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 48, color: colors.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                'be_first_to_discuss'.tr(args: [widget.boardname]),
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _posts.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final post = _posts[index];
        return AnimatedListItem(
          index: index,
          child: PostListTile(
            post: post,
            onTap: () async {
              await Navigator.of(context, rootNavigator: true).push(
                SlideRoute(
                  builder: (_) => EnlargePost.fromPost(
                    boardname: widget.boardname,
                    post: post,
                  ),
                ),
              );
              _load();
            },
          ),
        );
      },
      separatorBuilder: (_, __) => Divider(
        thickness: 1,
        color: colors.listDivider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollTop) ...[
            FloatingActionButton.small(
              heroTag: 'scrollTop',
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              backgroundColor: colors.surface,
              foregroundColor: colors.textTitle,
              elevation: 2,
              child: const Icon(Icons.arrow_upward_rounded, size: 20),
            ),
            const SizedBox(height: 8),
          ],
          if (_showWriteButton) WritePostFab(
            onPressed: () async {
              if (context.read<UserProvider>().currentUserId == null) {
                context.showInfoSnackbar('no_login_info'.tr());
                return;
              }
              await Navigator.push(
                context,
                SlideRoute(
                  builder: (_) => WritePostScreen(
                    title: 'write_post'.tr(),
                    onSubmit: (t, c, a, img) async {
                      await _postService.createPost(
                          boardType: _serviceBoardType, title: t, content: c, anonymous: a, imageObjectKey: img);
                      AppEvents.postChanged.value++;
                    },
                  ),
                ),
              );
              _load();
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          SecondaryAppBar(title: widget.boardname),
          Padding(
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
                style: TextStyle(color: colors.textTitle, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'search_posts_hint'.tr(),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            setSearchState(() {});
                            setState(() { _searchResults = null; _isSearching = false; });
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          if (_isPaginated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _SortChip(
                    label: 'sort_latest'.tr(),
                    selected: _sort == _sortLatest,
                    onTap: () {
                      setState(() => _sort = _sortLatest);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'sort_popular'.tr(),
                    selected: _sort == _sortPopular,
                    onTap: () {
                      setState(() => _sort = _sortPopular);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _load,
              child: _loading ? _buildSkeletonList() : _buildList(colors),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animXFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.activate : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
