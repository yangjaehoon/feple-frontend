import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_write_post_fab.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/screen/main/tab/my_page/s_other_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feple/provider/user_provider.dart';

class BoardPostList extends StatefulWidget {
  final String boardName;
  final Future<PostCursorPage> Function({int? cursor, int size}) fetchPage;
  final String writeScreenTitle;
  final Future<void> Function(String title, String content, bool anonymous, String? imageObjectKey) onSubmitPost;

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

class _BoardPostListState extends State<BoardPostList> {
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
      final result = await widget.fetchPage(size: 20);
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
      final result = await widget.fetchPage(size: 20);
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
      final result = await widget.fetchPage(cursor: _nextCursor, size: 20);
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
        if (mounted) _refresh();
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
            onRefresh: _refresh,
            child: _buildContent(colors),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_isLoading) {
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
          child: PostListTile(
            post: post,
            onTap: () async {
              await Navigator.of(context, rootNavigator: true).push(
                SlideRoute(
                  builder: (_) => PostDetailCard.fromPost(
                    boardName: widget.boardName,
                    post: post,
                  ),
                ),
              );
              if (mounted) _refresh();
            },
            onAuthorTap: () => navigateToUserProfile(
              context,
              userId: post.userId,
              nickname: post.nickname,
              profileImageUrl: post.profileImageUrl,
              currentUserId: context.read<UserProvider>().currentUserId,
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => Divider(thickness: 1, color: colors.listDivider),
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
