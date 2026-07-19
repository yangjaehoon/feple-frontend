import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/post_cursor_controller.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_stat_row.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/material.dart';

class MyPostsView extends StatefulWidget {
  final int userId;
  final String? title;
  const MyPostsView({super.key, required this.userId, this.title});

  @override
  State<MyPostsView> createState() => _MyPostsViewState();
}

class _MyPostsViewState extends State<MyPostsView> {
  final _service = sl<UserActivityService>();
  final _scrollController = ScrollController();
  late final _controller = PostCursorController(
    fetchPage: ({cursor, size = 20}) =>
        _service.fetchPostsPage(widget.userId, cursor: cursor, size: size),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _scrollController.addListener(_onScroll);
    _controller.load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _onScroll() => _controller.onScroll(_scrollController);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: widget.title ?? 'my_posts'.tr()),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _controller.refresh,
              child: _buildContent(colors),
            ),
          ),
        ],
      ),
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
            SkeletonBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
            const SizedBox(height: 8),
            SkeletonBox(width: 160, height: 12, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
            const SizedBox(height: 8),
            Row(children: [
              SkeletonBox(width: 40, height: 10, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
              const SizedBox(width: 12),
              SkeletonBox(width: 40, height: 10, borderRadius: BorderRadius.circular(AppDimens.radiusXs)),
            ]),
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
        child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: _controller.load),
      );
    }
    final posts = _controller.posts;
    if (posts.isEmpty) {
      return RefreshableCenter(
        child: EmptyState(icon: Icons.article_outlined, title: 'no_posts'.tr()),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
      itemCount: posts.length + (_controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        final post = posts[index];
        return AnimatedListItem(
          index: index,
          child: ListTile(
            onTap: () async {
              await Navigator.of(context, rootNavigator: true).push(
                SlideRoute(
                  builder: (_) => PostDetailCard.fromPost(
                    boardName: post.boardDisplayName,
                    post: post,
                  ),
                ),
              );
              _controller.refresh();
            },
            title: Text(
              post.title,
              style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              post.boardDisplayName,
              style: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXs),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PostStatRow(likeCount: post.likeCount, commentCount: post.commentCount),
          ),
        );
      },
      separatorBuilder: (_, _) => Divider(thickness: 1, color: colors.listDivider),
    );
  }
}
