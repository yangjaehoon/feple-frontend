import 'date_format.dart';
import 'json_reader.dart';

class CommentDetail {
  final int id;
  final int postId;
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool certified;
  final String? userRole;
  final int? parentId;
  final int likeCount;
  final bool liked;
  final bool anonymous;
  final bool edited;

  const CommentDetail({
    required this.id,
    required this.postId,
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.certified,
    this.userRole,
    this.parentId,
    required this.likeCount,
    required this.liked,
    this.anonymous = false,
    this.edited = false,
  });

  factory CommentDetail.fromJson(Map<String, dynamic> json) {
    return CommentDetail(
      id: json.integer('id'),
      postId: json.integer('postId'),
      userId: json.integer('userId'),
      nickname: json.str('nickname', 'User'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
      content: json.str('content'),
      createdAt: parseServerDateTime(json.strOrNull('createdAt')),
      updatedAt: json.dateTimeOrNull('updatedAt'),
      certified: json.boolean('certified'),
      userRole: json.strOrNull('userRole'),
      parentId: json.intOrNull('parentId'),
      likeCount: json.integer('likeCount'),
      liked: json.boolean('liked'),
      anonymous: json.boolean('anonymous'),
      edited: json.boolean('edited'),
    );
  }

  CommentDetail copyWith({
    bool? liked,
    int? likeCount,
    String? content,
    DateTime? updatedAt,
    bool? edited,
  }) =>
      CommentDetail(
        id: id,
        postId: postId,
        userId: userId,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        certified: certified,
        userRole: userRole,
        parentId: parentId,
        likeCount: likeCount ?? this.likeCount,
        liked: liked ?? this.liked,
        anonymous: anonymous,
        edited: edited ?? this.edited,
      );

  bool get isEdited => edited;

  bool get isReply => parentId != null;
}
