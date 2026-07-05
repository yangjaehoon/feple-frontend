import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
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
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int? _nextCursor;

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
    setState(() { _isLoading = true; _hasError = false; _posts = []; _hasMore = true; _nextCursor = null; });
    try {
      final result = await _service.fetchPostsPage(widget.userId, size: 20);
      if (mounted) {
        setState(() {
          _posts = result.content;
          _hasMore = result.hasNext;
          _nextCursor = result.nextCursor;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await _service.fetchPostsPage(widget.userId, size: 20);
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
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _service.fetchPostsPage(widget.userId, cursor: _nextCursor, size: 20);
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
              onRefresh: _refresh,
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
            child: Center(child: EmptyState(icon: Icons.article_outlined, title: 'no_posts'.tr())),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        final post = _posts[index];
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
              _refresh();
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
