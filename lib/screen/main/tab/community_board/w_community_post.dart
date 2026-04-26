import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:feple/screen/main/tab/community_board/w_community_write_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';

class CommunityPost extends StatefulWidget {
  final String boardname;

  const CommunityPost({super.key, required this.boardname});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  String get _serviceBoardType {
    if (widget.boardname == 'companion_board'.tr()) return 'MateBoard';
    if (widget.boardname == 'hot_board'.tr()) return 'HotBoard';
    if (widget.boardname == 'free_board'.tr()) return 'FreeBoard';
    return widget.boardname;
  }

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchPosts(_serviceBoardType);
  }

  Future<void> _refresh() async {
    setState(() {
      _postsFuture = _postService.fetchPosts(_serviceBoardType);
    });
    await _postsFuture;
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: colors.backgroundMain,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          backgroundColor: colors.activate,
          onPressed: () {
            Navigator.push(
              context,
              SlideRoute(
                builder: (_) => WritePost(boardname: widget.boardname),
              ),
            ).then((_) => _refresh());
          },
          label: Text(
            'write_post'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: RefreshIndicator(
        color: colors.activate,
        onRefresh: _refresh,
        child: AsyncContentBuilder<List<Post>>(
          future: _postsFuture,
          onRetry: _refresh,
          loadingBuilder: (_) => _buildSkeletonList(),
          builder: (context, posts) {
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
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideRoute(
                          builder: (_) => EnralgePost(
                            boardname: widget.boardname,
                            id: post.id,
                            nickname: post.nickname,
                            title: post.title,
                            content: post.content,
                            heart: post.likeCount,
                            certified: post.certified,
                            userRole: post.userRole,
                          ),
                        ),
                      ).then((_) => _refresh());
                    },
                  ),
                );
              },
              separatorBuilder: (_, __) => Divider(
                thickness: 1,
                color: colors.listDivider,
              ),
            );
          },
        ),
      ),
    );
  }
}
