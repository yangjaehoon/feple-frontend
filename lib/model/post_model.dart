import 'json_reader.dart';

class Post {
  final int id;
  final String title;
  final String content;
  final String? boardType;
  final int likeCount;
  final int scrapCount;
  final int commentCount;
  final String nickname;
  final String? profileImageUrl;
  final List<String> imageUrls;
  final int? artistId;
  final String boardDisplayName;
  final bool certified;
  final String? userRole; // 'USER' | 'ARTIST' | 'ADMIN'
  final bool anonymous;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? userId;
  final int viewCount;
  final String? authorLevel;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.boardType,
    required this.likeCount,
    this.scrapCount = 0,
    this.commentCount = 0,
    required this.nickname,
    this.profileImageUrl,
    this.imageUrls = const [],
    this.artistId,
    this.boardDisplayName = '',
    this.certified = false,
    this.userRole,
    this.anonymous = false,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.viewCount = 0,
    this.authorLevel,
  });

  // JSON에서 객체로 변환
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json.integer('id'),
      title: json.str('title'),
      content: json.str('content'),
      boardType: json.strOrNull('boardType'),
      likeCount: json.integer('likeCount'),
      scrapCount: json.integer('scrapCount'),
      commentCount: json.integer('commentCount'),
      nickname: json.str('nickname'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
      imageUrls: json.stringList('imageUrls'),
      artistId: json.intOrNull('artistId'),
      boardDisplayName: json.str('boardDisplayName'),
      certified: json.boolean('certified'),
      userRole: json.strOrNull('userRole'),
      anonymous: json.boolean('anonymous'),
      createdAt: json.dateTimeOrNull('createdAt'),
      updatedAt: json.dateTimeOrNull('updatedAt'),
      userId: json.intOrNull('userId'),
      viewCount: json.integer('viewCount'),
      authorLevel: json.strOrNull('authorLevel'),
    );
  }
}

class PostCursorPage {
  final List<Post> content;
  final int? nextCursor;
  final bool hasNext;

  const PostCursorPage({required this.content, this.nextCursor, required this.hasNext});

  factory PostCursorPage.fromJson(Map<String, dynamic> json) => PostCursorPage(
        content: json.objectList('content').map(Post.fromJson).toList(),
        nextCursor: json.intOrNull('nextCursor'),
        hasNext: json.boolean('hasNext'),
      );
}
