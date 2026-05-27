import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_write_post_fab.dart';
import 'package:feple/common/widget/w_write_post_screen.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:flutter/material.dart';

class BoardPostListScreen extends StatefulWidget {
  final String boardname;
  final Future<List<Post>> Function() fetchPosts;
  final String writeScreenTitle;
  final Future<void> Function(String title, String content, bool anonymous) onSubmitPost;

  const BoardPostListScreen({
    super.key,
    required this.boardname,
    required this.fetchPosts,
    required this.writeScreenTitle,
    required this.onSubmitPost,
  });

  @override
  State<BoardPostListScreen> createState() => _BoardPostListScreenState();
}

class _BoardPostListScreenState extends State<BoardPostListScreen> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = widget.fetchPosts();
  }

  Future<void> _refresh() async {
    setState(() => _postsFuture = widget.fetchPosts());
    try {
      await _postsFuture;
    } catch (_) {}
  }

  Widget _buildFab() {
    return WritePostFab(
      onPressed: () async {
        await Navigator.push(
          context,
          SlideRoute(
            builder: (_) => WritePostScreen(
              title: widget.writeScreenTitle,
              onSubmit: widget.onSubmitPost,
            ),
          ),
        );
        _refresh();
      },
    );
  }

  Widget _buildPostList(AbstractThemeColors colors, List<Post> posts) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
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
      separatorBuilder: (_, __) =>
          Divider(thickness: 1, color: colors.listDivider),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return Column(
      children: [
        SecondaryAppBar(title: widget.boardname),
        Expanded(
          child: RefreshIndicator(
            color: colors.activate,
            onRefresh: _refresh,
            child: AsyncContentBuilder<List<Post>>(
              future: _postsFuture,
              onRetry: _refresh,
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
              builder: (context, posts) => _buildPostList(colors, posts),
            ),
          ),
        ),
      ],
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
