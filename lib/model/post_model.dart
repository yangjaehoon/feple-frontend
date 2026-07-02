import 'package:feple/common/constant/user_roles.dart';

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
  final String? imageUrl;
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
    this.imageUrl,
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

  bool get isAdmin => userRole == kRoleAdmin;
  bool get isArtist => userRole == kRoleArtist;

  // JSON에서 객체로 변환
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      boardType: json['boardType'] as String?,
      likeCount: (json['likeCount'] as num).toInt(),
      scrapCount: json['scrapCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      artistId: json['artistId'] as int?,
      boardDisplayName: json['boardDisplayName'] as String? ?? '',
      certified: json['certified'] as bool? ?? false,
      userRole: json['userRole'] as String?,
      anonymous: json['anonymous'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      userId: (json['userId'] as num?)?.toInt(),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      authorLevel: json['authorLevel'] as String?,
    );
  }
}

class PostCursorPage {
  final List<Post> content;
  final int? nextCursor;
  final bool hasNext;

  const PostCursorPage({required this.content, this.nextCursor, required this.hasNext});

  factory PostCursorPage.fromJson(Map<String, dynamic> json) => PostCursorPage(
        content: ((json['content'] as List<dynamic>?) ?? []).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
        nextCursor: (json['nextCursor'] as num?)?.toInt(),
        hasNext: json['hasNext'] as bool,
      );
}
