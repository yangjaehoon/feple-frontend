import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';

class FestivalBoardScreen extends StatefulWidget {
  final int festivalId;
  final String festivalName;

  const FestivalBoardScreen({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  State<FestivalBoardScreen> createState() => _FestivalBoardScreenState();
}

class _FestivalBoardScreenState extends State<FestivalBoardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<_BoardTab> _tabs;

  @override
  void initState() {
    super.initState();
    final postService = sl<PostService>();
    _tabs = [
      _BoardTab(
        name: 'name_board'.tr(args: [widget.festivalName]),
        fetchPage: ({int? cursor, int size = 20}) =>
            postService.fetchFestivalPostsPage(widget.festivalId, cursor: cursor, size: size),
        submit: (t, c, a, img) => postService.createFestivalPost(
            festivalId: widget.festivalId, title: t, content: c, anonymous: a, imageObjectKey: img),
      ),
      _BoardTab(
        name: 'companion_board'.tr(),
        fetchPage: ({int? cursor, int size = 20}) =>
            postService.fetchFestivalCompanionPostsPage(widget.festivalId, cursor: cursor, size: size),
        submit: (t, c, a, img) => postService.createFestivalCompanionPost(
            festivalId: widget.festivalId, title: t, content: c, anonymous: a, imageObjectKey: img),
      ),
      _BoardTab(
        name: 'ticket_board'.tr(),
        fetchPage: ({int? cursor, int size = 20}) =>
            postService.fetchFestivalTicketPostsPage(widget.festivalId, cursor: cursor, size: size),
        submit: (t, c, a, img) => postService.createFestivalTicketPost(
            festivalId: widget.festivalId, title: t, content: c, anonymous: a, imageObjectKey: img),
      ),
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openWrite(int index) async {
    final tab = _tabs[index];
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => WritePost(
          title: tab.name,
          onSubmit: tab.submit,
        ),
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
          _buildAppBarSection(colors),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(
                _tabs.length,
                (i) => _FestivalBoardTabContent(
                  key: ValueKey(i),
                  tab: _tabs[i],
                  onPostCreated: () => _openWrite(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(AbstractThemeColors colors) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.fabBottomPadding),
        child: FloatingActionButton.extended(
          backgroundColor: colors.activate,
          onPressed: () => _openWrite(_tabController.index),
          label: Text(
            'write_post'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAppBarSection(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: colors.appBarColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: AppDimens.appBarHeight,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'back'.tr(),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.festivalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppDimens.fontSizeTitle,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppDimens.fontSizeMd),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: AppDimens.fontSizeMd),
              tabs: [
                Tab(text: 'free_board'.tr()),
                Tab(text: 'companion_tab'.tr()),
                Tab(text: 'ticket_tab'.tr()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FestivalBoardTabContent extends StatefulWidget {
  final _BoardTab tab;
  final VoidCallback onPostCreated;

  const _FestivalBoardTabContent({
    super.key,
    required this.tab,
    required this.onPostCreated,
  });

  @override
  State<_FestivalBoardTabContent> createState() => _FestivalBoardTabContentState();
}

class _FestivalBoardTabContentState extends State<_FestivalBoardTabContent>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  List<Post> _posts = [];
  bool _loading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isNavigating = false;
  int? _nextCursor;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; _posts = []; _hasMore = true; _nextCursor = null; });
    try {
      final result = await widget.tab.fetchPage(size: 20);
      if (mounted) {
        setState(() {
          _posts = result.content;
          _hasMore = result.hasNext;
          _nextCursor = result.nextCursor;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await widget.tab.fetchPage(size: 20);
      if (mounted) {
        setState(() {
          _posts = result.content;
          _hasMore = result.hasNext;
          _nextCursor = result.nextCursor;
          _hasError = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _loading) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await widget.tab.fetchPage(cursor: _nextCursor, size: 20);
      if (mounted) {
        setState(() {
          _posts = [..._posts, ...result.content];
          _hasMore = result.hasNext;
          _nextCursor = result.nextCursor;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openPost(Post post) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await Navigator.of(context, rootNavigator: true).push(
        SlideRoute(
          builder: (_) => PostDetailCard.fromPost(boardName: widget.tab.name, post: post),
        ),
      );
      if (!mounted) return;
      _refresh();
    } finally {
      if (mounted) _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.appColors;
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: _refresh,
      child: _buildContent(colors),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SkeletonBox(width: 40, height: 10, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
              const SizedBox(width: 8),
              SkeletonBox(width: 60, height: 10, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
            ]),
            const SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
            const SizedBox(height: 6),
            SkeletonBox(width: 200, height: 12, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
            const SizedBox(height: 8),
            Row(children: [
              SkeletonBox(width: 36, height: 10, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
              const SizedBox(width: 12),
              SkeletonBox(width: 36, height: 10, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_loading) {
      return _buildSkeleton(colors);
    }
    if (_hasError) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: _load)),
          ),
        ),
      );
    }
    if (_posts.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: EmptyState(
                icon: Icons.article_outlined,
                title: 'no_posts_yet'.tr(),
                subtitle: 'first_post_hint'.tr(),
              ),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        return PostListTile(
          post: _posts[i],
          onTap: () => _openPost(_posts[i]),
        );
      },
      separatorBuilder: (_, __) => Divider(thickness: 1, color: colors.listDivider),
    );
  }
}

typedef _SubmitFn = Future<void> Function(String, String, bool, String?);

class _BoardTab {
  final String name;
  final Future<PostCursorPage> Function({int? cursor, int size}) fetchPage;
  final _SubmitFn submit;

  const _BoardTab({
    required this.name,
    required this.fetchPage,
    required this.submit,
  });
}
