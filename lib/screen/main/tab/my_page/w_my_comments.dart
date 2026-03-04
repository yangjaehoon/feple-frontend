import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'package:flutter/material.dart';

class MyCommentsScreen extends StatefulWidget {
  final int userId;
  const MyCommentsScreen({super.key, required this.userId});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  late Future<List<_MyComment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchComments();
  }

  Future<List<_MyComment>> _fetchComments() async {
    final resp = await DioClient.dio.get('/users/${widget.userId}/comments');
    return (resp.data as List).map((e) => _MyComment.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 댓글'),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      body: FutureBuilder<List<_MyComment>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.loadingIndicator));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('작성한 댓글이 없습니다.', style: TextStyle(color: colors.textSecondary)),
            );
          }
          final comments = snapshot.data!;
          return ListView.separated(
            itemCount: comments.length,
            separatorBuilder: (_, __) => Divider(thickness: 1, color: colors.listDivider),
            itemBuilder: (context, index) {
              final c = comments[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnralgePost(
                        boardname: c.boardDisplayName,
                        id: c.postId,
                        nickname: c.postNickname,
                        title: c.postTitle,
                        content: c.postContent,
                        heart: c.postLikeCount,
                      ),
                    ),
                  );
                },
                title: Text(
                  c.content,
                  style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${c.boardDisplayName} • ${c.postTitle}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Icon(Icons.chat_bubble_rounded, color: colors.activate, size: 20),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyComment {
  final int commentId;
  final String content;
  final int postId;
  final String postTitle;
  final String postContent;
  final String postNickname;
  final int postLikeCount;
  final String boardDisplayName;

  const _MyComment({
    required this.commentId,
    required this.content,
    required this.postId,
    required this.postTitle,
    required this.postContent,
    required this.postNickname,
    required this.postLikeCount,
    required this.boardDisplayName,
  });

  factory _MyComment.fromJson(Map<String, dynamic> json) {
    return _MyComment(
      commentId: json['commentId'] as int,
      content: json['content'] as String,
      postId: json['postId'] as int,
      postTitle: json['postTitle'] as String,
      postContent: json['postContent'] as String,
      postNickname: json['postNickname'] as String,
      postLikeCount: json['postLikeCount'] as int,
      boardDisplayName: json['boardDisplayName'] as String,
    );
  }
}
