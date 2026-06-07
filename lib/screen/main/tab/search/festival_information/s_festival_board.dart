import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_write_post_screen.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
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
  late List<Future<List<Post>>?> _futures;
  late List<int> _tabRefreshKeys;

  @override
  void initState() {
    super.initState();
    final postService = sl<PostService>();
    _tabs = [
      _BoardTab(
        name: 'name_board'.tr(args: [widget.festivalName]),
        fetch: () => postService.fetchFestivalPosts(widget.festivalId),
        submit: (t, c, a, img) => postService.createFestivalPost(
            festivalId: widget.festivalId, title: t, content: c, anonymous: a, imageObjectKey: img),
      ),
      _BoardTab(
        name: 'companion_board'.tr(),
        fetch: () => postService.fetchFestivalCompanionPosts(widget.festivalId),
        submit: (t, c, a, img) => postService.createFestivalCompanionPost(
            festivalId: widget.festivalId, title: t, content: c, anonymous: a, imageObjectKey: img),
      ),
      _BoardTab(
        name: 'ticket_board'.tr(),
        fetch: () => postService.fetchFestivalTicketPosts(widget.festivalId),
        submit: (t, c, a, img) => postService.createFestivalTicketPost(
            festivalId: widget.festivalId, title: t, content: c, anonymous: a, imageObjectKey: img),
      ),
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tabRefreshKeys = List.filled(_tabs.length, 0);
    _futures = List.filled(_tabs.length, null);
    _futures[0] = _tabs[0].fetch();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _futures[_tabController.index] ??= _tabs[_tabController.index].fetch();
      });
    }
  }

  void _refreshTab(int index) {
    setState(() {
      _futures[index] = _tabs[index].fetch();
      _tabRefreshKeys[index]++;
    });
  }

  Future<void> _openWrite(int index) async {
    final tab = _tabs[index];
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => WritePostScreen(
          title: tab.name,
          onSubmit: tab.submit,
        ),
      ),
    );
    if (!mounted) return;
    _refreshTab(index);
  }

  Widget _buildTabContent(int index, AbstractThemeColors colors) {
    final future = _futures[index];
    if (future == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final boardName = _tabs[index].name;
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: () async {
        _refreshTab(index);
        try { await _futures[index]!; } catch (_) {}
      },
      child: AsyncContentBuilder<List<Post>>(
        key: ValueKey(_tabRefreshKeys[index]),
        future: future,
        onRetry: () => _refreshTab(index),
        emptyBuilder: (_) => ListView(
          children: [
            const SizedBox(height: 80),
            EmptyState(
              icon: Icons.article_outlined,
              title: 'no_posts_yet'.tr(),
              subtitle: 'first_post_hint'.tr(),
            ),
          ],
        ),
        builder: (ctx, posts) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final post = posts[i];
            return PostListTile(
              post: post,
              onTap: () async {
                await Navigator.of(ctx, rootNavigator: true).push(
                  SlideRoute(
                    builder: (_) => EnlargePost.fromPost(boardName: boardName, post: post),
                  ),
                );
                if (!mounted) return;
                _refreshTab(index);
              },
            );
          },
          separatorBuilder: (_, __) =>
              Divider(thickness: 1, color: colors.listDivider),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tabIndex = _tabController.index;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      floatingActionButton: _buildFab(colors, tabIndex),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          _buildAppBarSection(colors),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (i) => _buildTabContent(i, colors)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(AbstractThemeColors colors, int tabIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.fabBottomPadding),
      child: FloatingActionButton.extended(
        backgroundColor: colors.activate,
        onPressed: () => _openWrite(tabIndex),
        label: Text(
          'write_post'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
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
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.festivalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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

typedef _SubmitFn = Future<void> Function(String, String, bool, String?);

class _BoardTab {
  final String name;
  final Future<List<Post>> Function() fetch;
  final _SubmitFn submit;

  const _BoardTab({
    required this.name,
    required this.fetch,
    required this.submit,
  });
}
