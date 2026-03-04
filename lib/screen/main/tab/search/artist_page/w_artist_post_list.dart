import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/post_model.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_artist_write_post.dart';
import 'package:fast_app_base/service/post_service.dart';
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
  final PostService _postService = PostService();
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

  String get _boardname => '${widget.artistName} 게시판';

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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          backgroundColor: colors.activate,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistWritePost(
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
              ),
            ).then((_) => _refresh());
          },
          label: const Text(
            '글 쓰기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
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
                child: CircularProgressIndicator(color: colors.loadingIndicator),
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(height: 200),
                  Center(
                    child: Text('Failed to load: ${snapshot.error}',
                        style: TextStyle(color: colors.textSecondary)),
                  ),
                ],
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 200),
                  Center(
                    child: Text('아직 게시글이 없습니다.',
                        style: TextStyle(color: colors.textSecondary)),
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
                return PostListTile(
                  post: post,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
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
