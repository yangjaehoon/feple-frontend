import 'json_reader.dart';

class MyComment {
  final int commentId;
  final String content;
  final int postId;
  final String postTitle;
  final String postContent;
  final String postNickname;
  final int postLikeCount;
  final String boardDisplayName;

  const MyComment({
    required this.commentId,
    required this.content,
    required this.postId,
    required this.postTitle,
    required this.postContent,
    required this.postNickname,
    required this.postLikeCount,
    required this.boardDisplayName,
  });

  factory MyComment.fromJson(Map<String, dynamic> json) => MyComment(
        commentId: json.integer('commentId'),
        content: json.str('content'),
        postId: json.integer('postId'),
        postTitle: json.str('postTitle'),
        postContent: json.str('postContent'),
        postNickname: json.str('postNickname'),
        postLikeCount: json.integer('postLikeCount'),
        boardDisplayName: json.str('boardDisplayName'),
      );
}
