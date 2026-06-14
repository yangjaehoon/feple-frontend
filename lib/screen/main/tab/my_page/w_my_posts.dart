import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/material.dart';

class MyPostsScreen extends StatefulWidget {
  final int userId;
  const MyPostsScreen({super.key, required this.userId});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _service = sl<UserActivityService>();
  final _scrollController = ScrollController();
  List<Post> _posts = [];
  bool _loading = true;
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
    setState(() { _loading = true; _hasError = false; _posts = []; _hasMore = true; _nextCursor = null; });
    try {
      final result = await _service.fetchPostsPage(widget.userId, size: 20);
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
    if (_isLoadingMore || !_hasMore || _loading) return;
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
          SecondaryAppBar(title: 'my_posts'.tr()),
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

  Widget _buildContent(AbstractThemeColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
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
                  builder: (_) => EnlargePost.fromPost(
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
            ),
            subtitle: Text(
              post.boardDisplayName,
              style: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXs),
            ),
            trailing: PostStatRow(likeCount: post.likeCount, commentCount: post.commentCount),
          ),
        );
      },
      separatorBuilder: (_, __) => Divider(thickness: 1, color: colors.listDivider),
    );
  }
}
