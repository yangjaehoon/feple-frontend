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
        commentId: (json['commentId'] as num).toInt(),
        content: json['content'] as String,
        postId: (json['postId'] as num).toInt(),
        postTitle: json['postTitle'] as String,
        postContent: json['postContent'] as String,
        postNickname: json['postNickname'] as String,
        postLikeCount: (json['postLikeCount'] as num).toInt(),
        boardDisplayName: json['boardDisplayName'] as String,
      );
}
