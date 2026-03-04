class Post {
  final int id;
  final String title;
  final String content;
  final String? boardType;
  final int likeCount;
  final int commentCount;
  final String nickname;
  final int? artistId;
  final String boardDisplayName;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.boardType,
    required this.likeCount,
    this.commentCount = 0,
    required this.nickname,
    this.artistId,
    this.boardDisplayName = '게시판',
  });

  // JSON에서 객체로 변환
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      boardType: json['boardType'] as String?,
      likeCount: json['likeCount'] as int,
      commentCount: json['commentCount'] as int? ?? 0,
      nickname: json['nickname'] as String,
      artistId: json['artistId'] as int?,
      boardDisplayName: json['boardDisplayName'] as String? ?? '게시판',
    );
  }
}
