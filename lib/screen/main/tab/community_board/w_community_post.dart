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

  const CommunityPost({super.key, required this.boardname});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  static const _pageSize = 20;

  final PostService _postService = sl<PostService>();
  final ScrollController _scrollController = ScrollController();

  final List<Post> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _page = 0;
  int _loadId = 0;

  String get _serviceBoardType {
    if (widget.boardname == 'companion_board'.tr()) return BoardTypes.mate;
    if (widget.boardname == 'hot_board'.tr()) return BoardTypes.hot;
    if (widget.boardname == 'free_board'.tr()) return BoardTypes.free;
    return widget.boardname;
  }

  bool get _isPaginated =>
      _serviceBoardType == BoardTypes.free || _serviceBoardType == BoardTypes.mate;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore || !_isPaginated) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    final myId = ++_loadId;
    setState(() { _loading = true; _hasError = false; _posts.clear(); _page = 0; _hasMore = true; });
    try {
      final items = _isPaginated
          ? await _postService.fetchPostsPage(_serviceBoardType, page: 0, size: _pageSize)
          : await _postService.fetchPosts(_serviceBoardType);
      if (!mounted || _loadId != myId) return;
      setState(() {
        _posts.addAll(items);
        _loading = false;
        if (_isPaginated) {
          _page = 1;
          _hasMore = items.length == _pageSize;
        }
      });
    } catch (_) {
      if (mounted && _loadId == myId) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final items = await _postService.fetchPostsPage(_serviceBoardType, page: _page, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _posts.addAll(items);
        _page++;
        _hasMore = items.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    await _load();
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
              onPressed: _refresh,
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
        child: Text('no_posts_yet'.tr(), style: TextStyle(color: colors.textSecondary)),
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
              _refresh();
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
      floatingActionButton: WritePostFab(
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
                onSubmit: (t, c, a) async {
                  await _postService.createPost(
                      boardType: _serviceBoardType, title: t, content: c, anonymous: a);
                  AppEvents.postChanged.value++;
                },
              ),
            ),
          );
          _refresh();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          SecondaryAppBar(title: widget.boardname),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _refresh,
              child: _loading ? _buildSkeletonList() : _buildList(colors),
            ),
          ),
        ],
      ),
    );
  }
}
