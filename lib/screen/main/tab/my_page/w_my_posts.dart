import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/post_model.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'package:flutter/material.dart';

class MyPostsScreen extends StatefulWidget {
  final int userId;
  const MyPostsScreen({super.key, required this.userId});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late Future<List<Post>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    final resp = await DioClient.dio.get('/users/${widget.userId}/posts');
    return (resp.data as List).map((e) => Post.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 게시글'),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      body: FutureBuilder<List<Post>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.loadingIndicator));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('작성한 게시글이 없습니다.', style: TextStyle(color: colors.textSecondary)),
            );
          }
          final posts = snapshot.data!;
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, __) => Divider(thickness: 1, color: colors.listDivider),
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnralgePost(
                        boardname: post.boardDisplayName,
                        id: post.id,
                        nickname: post.nickname,
                        title: post.title,
                        content: post.content,
                        heart: post.likeCount,
                      ),
                    ),
                  );
                },
                title: Text(
                  post.title,
                  style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  post.boardDisplayName,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded, color: Colors.pink, size: 16),
                    const SizedBox(width: 4),
                    Text(post.likeCount.toString(),
                        style: TextStyle(color: colors.textTitle, fontSize: 13)),
                    const SizedBox(width: 8),
                    Icon(Icons.chat_bubble_outline_rounded, color: colors.textSecondary, size: 15),
                    const SizedBox(width: 4),
                    Text(post.commentCount.toString(),
                        style: TextStyle(color: colors.textTitle, fontSize: 13)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
