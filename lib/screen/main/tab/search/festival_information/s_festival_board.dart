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
  late final PostService _svc;
  late List<Future<List<Post>>> _futures;

  @override
  void initState() {
    super.initState();
    _svc = sl<PostService>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  void _loadAll() {
    _futures = [
      _svc.fetchFestivalPosts(widget.festivalId),
      _svc.fetchFestivalCompanionPosts(widget.festivalId),
      _svc.fetchFestivalTicketPosts(widget.festivalId),
    ];
  }

  void _refreshTab(int index) {
    final future = switch (index) {
      0 => _svc.fetchFestivalPosts(widget.festivalId),
      1 => _svc.fetchFestivalCompanionPosts(widget.festivalId),
      _ => _svc.fetchFestivalTicketPosts(widget.festivalId),
    };
    setState(() => _futures[index] = future);
  }

  List<String> get _boardNames => [
    'name_board'.tr(args: [widget.festivalName]),
    'companion_board'.tr(),
    'ticket_board'.tr(),
  ];

  List<Future<void> Function(String, String)> get _submitFns => [
    (t, c) => _svc.createFestivalPost(festivalId: widget.festivalId, title: t, content: c),
    (t, c) => _svc.createFestivalCompanionPost(festivalId: widget.festivalId, title: t, content: c),
    (t, c) => _svc.createFestivalTicketPost(festivalId: widget.festivalId, title: t, content: c),
  ];

  Future<void> _openWrite(int index) async {
    final names = _boardNames;
    final fns = _submitFns;
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => WritePostScreen(
          title: names[index],
          onSubmit: fns[index],
        ),
      ),
    );
    _refreshTab(index);
  }

  Widget _buildTabContent(int index, AbstractThemeColors colors) {
    final boardname = _boardNames[index];
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: () async {
        _refreshTab(index);
        try { await _futures[index]; } catch (_) {}
      },
      child: AsyncContentBuilder<List<Post>>(
        future: _futures[index],
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
                    builder: (_) => EnlargePost.fromPost(boardname: boardname, post: post),
                  ),
                );
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          backgroundColor: colors.activate,
          onPressed: () => _openWrite(tabIndex),
          label: Text(
            'write_post'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          SafeArea(
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
                      Tab(text: 'board'.tr()),
                      Tab(text: 'companion_tab'.tr()),
                      Tab(text: 'ticket_tab'.tr()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (i) => _buildTabContent(i, colors)),
            ),
          ),
        ],
      ),
    );
  }
}
