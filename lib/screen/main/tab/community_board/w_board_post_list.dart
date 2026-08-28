import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/post_cursor_controller.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/post_cursor_controller_listener.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_write_post_fab.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/model/post_draft.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/screen/main/tab/my_page/s_other_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/forced_refresh.dart';

class BoardPostList extends StatefulWidget {
  final String boardName;
  final Future<PostCursorPage> Function({int? cursor, int size}) fetchPage;
  final String writeScreenTitle;
  final Future<void> Function(PostDraft draft) onSubmitPost;

  const BoardPostList({
    super.key,
    required this.boardName,
    required this.fetchPage,
    required this.writeScreenTitle,
    required this.onSubmitPost,
  });

  @override
  State<BoardPostList> createState() => _BoardPostListState();
}

class _BoardPostListState extends State<BoardPostList>
    with PostCursorControllerListener<BoardPostList> {
  final _scrollController = ScrollController();
  late final _controller = PostCursorController(fetchPage: widget.fetchPage);

  @override
  PostCursorController get postCursorController => _controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(onPostCursorControllerChanged);
    _scrollController.addListener(_onScroll);
    _controller.load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.removeListener(onPostCursorControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() => _controller.onScroll(_scrollController);

  Widget _buildFab() {
    return WritePostFab(
      onPressed: () async {
        await Navigator.push(
          context,
          SlideRoute(
            builder: (_) => WritePost(
              title: widget.writeScreenTitle,
              onSubmit: widget.onSubmitPost,
            ),
          ),
        );
        if (mounted) unawaited(_controller.refresh());
      },
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return Column(
      children: [
        SecondaryAppBar(title: widget.boardName),
        Expanded(
          child: RefreshIndicator(
            color: colors.activate,
            onRefresh: () => withForcedRefresh(_controller.refresh),
            child: _buildContent(colors),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) =>
          Divider(thickness: 1, color: colors.listDivider),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            ),
            const SizedBox(height: AppDimens.space8),
            SkeletonBox(
              width: 160,
              height: 12,
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            ),
            const SizedBox(height: AppDimens.space8),
            Row(
              children: [
                SkeletonBox(
                  width: 40,
                  height: 10,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
                const SizedBox(width: AppDimens.space12),
                SkeletonBox(
                  width: 40,
                  height: 10,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_controller.isLoading) {
      return _buildSkeleton(colors);
    }
    if (_controller.hasError) {
      return RefreshableCenter(
        child: ErrorState.network(
          _controller.error!,
          onRetry: _controller.load,
        ),
      );
    }
    final posts = _controller.posts;
    if (posts.isEmpty) {
      return RefreshableCenter(
        child: EmptyState(
          icon: Icons.article_outlined,
          title: 'no_posts_yet'.tr(),
          subtitle: 'first_post_hint'.tr(),
        ),
      );
    }
    return _buildPostList(colors, posts);
  }

  Future<void> _openPost(BuildContext context, Post post) async {
    await Navigator.of(context, rootNavigator: true).push(
      SlideRoute(
        builder: (_) =>
            PostDetailCard.fromPost(boardName: widget.boardName, post: post),
      ),
    );
    if (mounted) unawaited(_controller.refresh());
  }

  Widget _buildPostItem(BuildContext context, List<Post> posts, int index) {
    if (index == posts.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final post = posts[index];
    return AnimatedListItem(
      index: index,
      child: PostListTile(
        post: post,
        onTap: () => _openPost(context, post),
        onAuthorTap: () => navigateToPostAuthor(
          context,
          userId: post.userId,
          nickname: post.nickname,
          profileImageUrl: post.profileImageUrl,
        ),
      ),
    );
  }

  Widget _buildPostList(AbstractThemeColors colors, List<Post> posts) {
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
      itemCount: posts.length + (_controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) => _buildPostItem(context, posts, index),
      separatorBuilder: (_, _) =>
          Divider(thickness: 1, color: colors.listDivider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _buildBody(colors),
    );
  }
}
