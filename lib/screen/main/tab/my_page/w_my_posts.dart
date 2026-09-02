import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/post_cursor_controller.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_list_row_skeleton.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_stat_row.dart';
import 'package:feple/screen/main/tab/my_page/w_status_badge.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/forced_refresh.dart';

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

  void _onControllerChanged() {
    setState(() {});
    final refreshError = _controller.refreshError;
    if (refreshError != null) {
      _controller.clearRefreshError();
      context.showErrorSnackbar(refreshError);
    }
  }

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
              onRefresh: () => withForcedRefresh(_controller.refresh),
              child: _buildContent(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_controller.isLoading) {
      return const ListRowSkeleton(
        showLeading: false,
        showStatRow: true,
        divided: true,
        itemCount: 6,
      );
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
        child: EmptyState(icon: Icons.article_outlined, title: 'no_posts'.tr()),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
      itemCount: posts.length + (_controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) => index == posts.length
          ? _buildLoadMoreFooter()
          : _buildPostTile(context, posts[index], index, colors),
      separatorBuilder: (_, _) =>
          Divider(thickness: 1, color: colors.listDivider),
    );
  }

  Widget _buildLoadMoreFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildPostTile(
    BuildContext context,
    Post post,
    int index,
    AbstractThemeColors colors,
  ) {
    return AnimatedListItem(
      index: index,
      child: ListTile(
        onTap: () => _openPost(context, post),
        title: Text(
          post.title,
          style: TextStyle(
            color: colors.textTitle,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                post.boardDisplayName,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: AppDimens.fontSizeXs,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 익명 글은 타인 프로필에선 애초에 목록에 안 나오므로, 여기 보이면 본인 글이다.
            if (post.anonymous) ...[
              const SizedBox(width: AppDimens.space6),
              StatusBadge(
                color: colors.textSecondary,
                label: 'anonymous_tag'.tr(),
              ),
            ],
          ],
        ),
        trailing: PostStatRow(
          likeCount: post.likeCount,
          commentCount: post.commentCount,
        ),
      ),
    );
  }

  Future<void> _openPost(BuildContext context, Post post) async {
    await Navigator.of(context, rootNavigator: true).push(
      SlideRoute(
        builder: (_) => PostDetailCard.fromPost(
          boardName: post.boardDisplayName,
          post: post,
        ),
      ),
    );
    if (mounted) unawaited(_controller.refresh());
  }
}
