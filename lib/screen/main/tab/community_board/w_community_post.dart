import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_write_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:fast_app_base/service/post_service.dart';
import 'package:fast_app_base/model/post_model.dart';

class CommunityPost extends StatefulWidget {
  final String boardname;

  const CommunityPost({super.key, required this.boardname});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  final PostService _postService = PostService();
  late Future<List<Post>> _postsFuture;

  String get _serviceBoardType {
    switch (widget.boardname) {
      case 'GetuserBoard':
        return 'MateBoard';
      default:
        return widget.boardname;
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
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
                builder: (_) => WritePost(boardname: widget.boardname),
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
                    child: Text('No data available.',
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
                          boardname: widget.boardname,
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
