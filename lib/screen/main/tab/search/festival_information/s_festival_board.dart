import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/screen/main/tab/my_page/s_other_user_profile.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../provider/user_provider.dart';

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
        submit: (title, content, anonymous, imageObjectKey) => postService.createFestivalPost(
            festivalId: widget.festivalId, title: title, content: content, anonymous: anonymous, imageObjectKey: imageObjectKey),
      ),
      _BoardTab(
        name: 'companion_board'.tr(),
        fetchPage: ({int? cursor, int size = 20}) =>
            postService.fetchFestivalCompanionPostsPage(widget.festivalId, cursor: cursor, size: size),
        submit: (title, content, anonymous, imageObjectKey) => postService.createFestivalCompanionPost(
            festivalId: widget.festivalId, title: title, content: content, anonymous: anonymous, imageObjectKey: imageObjectKey),
      ),
      _BoardTab(
        name: 'ticket_board'.tr(),
        fetchPage: ({int? cursor, int size = 20}) =>
            postService.fetchFestivalTicketPostsPage(widget.festivalId, cursor: cursor, size: size),
        submit: (title, content, anonymous, imageObjectKey) => postService.createFestivalTicketPost(
            festivalId: widget.festivalId, title: title, content: content, anonymous: anonymous, imageObjectKey: imageObjectKey),
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
          heroTag: null,
          backgroundColor: colors.activate,
          onPressed: () => _openWrite(_tabController.index),
          label: Text(
            'write_post'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700),
          ),
          icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onPrimary),
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
                    icon: Icon(Icons.arrow_back_ios_rounded, color: colors.appBarIconColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.festivalName,
                      style: TextStyle(
                        color: colors.appBarIconColor,
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
              labelColor: colors.appBarIconColor,
              unselectedLabelColor: colors.appBarIconColor.withValues(alpha: 0.54),
              indicatorColor: colors.appBarIconColor,
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
    with AutomaticKeepAliveClientMixin, NavigationGuard {
  final _scrollController = ScrollController();
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int? _nextCursor;
  // load/refresh와 loadMore가 겹칠 때 늦게 도착한 stale 응답을 버리기 위한 가드
  int _loadId = 0;

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
    final myId = ++_loadId;
    // 진행 중이던 loadMore를 무효화 — 그 결과가 나중에 와도 _loadId 가드로 버려짐
    setState(() {
      _isLoading = true;
      _hasError = false;
      _posts = [];
      _hasMore = true;
      _nextCursor = null;
      _isLoadingMore = false;
    });
    try {
      final result = await widget.tab.fetchPage(size: 20);
      if (mounted && _loadId == myId) {
        setState(() {
          _posts = result.content;
          _hasMore = result.hasNext;
          _nextCursor = result.nextCursor;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && _loadId == myId) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _refresh() async {
    final myId = ++_loadId;
    if (_isLoadingMore) setState(() => _isLoadingMore = false);
    try {
      final result = await widget.tab.fetchPage(size: 20);
      if (mounted && _loadId == myId) {
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
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    final myId = _loadId;
    setState(() => _isLoadingMore = true);
    try {
      final result = await widget.tab.fetchPage(cursor: _nextCursor, size: 20);
      if (mounted && _loadId == myId) {
        setState(() {
          _posts = [..._posts, ...result.content];
          _hasMore = result.hasNext;
          _nextCursor = result.nextCursor;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted && _loadId == myId) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openPost(Post post) async {
    await guardedNavigate(() async {
      await Navigator.of(context, rootNavigator: true).push(
        SlideRoute(
          builder: (_) => PostDetailCard.fromPost(boardName: widget.tab.name, post: post),
        ),
      );
      if (!mounted) return;
      _refresh();
    });
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
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.divider),
      itemBuilder: (_, _) => Padding(
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
    if (_isLoading) {
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
        final post = _posts[i];
        return PostListTile(
          post: post,
          onTap: () => _openPost(post),
          onAuthorTap: () => navigateToUserProfile(
            context,
            userId: post.userId,
            nickname: post.nickname,
            profileImageUrl: post.profileImageUrl,
            currentUserId: context.read<UserProvider>().currentUserId,
          ),
        );
      },
      separatorBuilder: (_, _) => Divider(thickness: 1, color: colors.listDivider),
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
