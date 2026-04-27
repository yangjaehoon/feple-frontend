import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_write_post_fab.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_write_post.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

/// 아티스트별 전체 게시글 목록 화면
class ArtistPostListScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistPostListScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistPostListScreen> createState() => _ArtistPostListScreenState();
}

class _ArtistPostListScreenState extends State<ArtistPostListScreen> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchArtistPosts(widget.artistId);
  }

  Future<void> _refresh() async {
    setState(() {
      _postsFuture = _postService.fetchArtistPosts(widget.artistId);
    });
    await _postsFuture;
  }

  String get _boardname => 'name_board'.tr(args: [widget.artistName]);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(_boardname),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      floatingActionButton: WritePostFab(
        onPressed: () => Navigator.push(
          context,
          SlideRoute(
            builder: (_) => ArtistWritePost(
              artistId: widget.artistId,
              artistName: widget.artistName,
            ),
          ),
        ).then((_) => _refresh()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: RefreshIndicator(
        color: colors.activate,
        onRefresh: _refresh,
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child:
                    CircularProgressIndicator(color: colors.loadingIndicator),
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  ErrorState(
                    message: 'err_fetch_data'.tr(args: ['']),
                    onRetry: _refresh,
                  ),
                ],
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.article_outlined,
                    title: 'no_posts_yet'.tr(),
                    subtitle: 'first_post_hint'.tr(),
                  ),
                ],
              );
            }

            final posts = snapshot.data!;
            return ListView.separated(
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
                          boardname: _boardname,
                          id: post.id,
                          nickname: post.nickname,
                          title: post.title,
                          content: post.content,
                          heart: post.likeCount,
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
