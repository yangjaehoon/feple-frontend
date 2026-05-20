import 'package:feple/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

class CommentDetail {
  final int id;
  final int postId;
  final int userId;
  final String nickname;
  final String content;
  final DateTime createdAt;
  final bool certified;
  final String? userRole;
  final int? parentId;
  final int likeCount;
  final bool liked;

  const CommentDetail({
    required this.id,
    required this.postId,
    required this.userId,
    required this.nickname,
    required this.content,
    required this.createdAt,
    required this.certified,
    this.userRole,
    this.parentId,
    required this.likeCount,
    required this.liked,
  });

  factory CommentDetail.fromJson(Map<String, dynamic> json) {
    return CommentDetail(
      id: (json['id'] as num).toInt(),
      postId: (json['postId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      nickname: json['nickname'] as String? ?? 'User',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      certified: json['certified'] as bool? ?? false,
      userRole: json['userRole'] as String?,
      parentId: json['parentId'] != null ? (json['parentId'] as num).toInt() : null,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      liked: json['liked'] as bool? ?? false,
    );
  }

  CommentDetail copyWith({bool? liked, int? likeCount}) => CommentDetail(
        id: id,
        postId: postId,
        userId: userId,
        nickname: nickname,
        content: content,
        createdAt: createdAt,
        certified: certified,
        userRole: userRole,
        parentId: parentId,
        likeCount: likeCount ?? this.likeCount,
        liked: liked ?? this.liked,
      );

  bool get isReply => parentId != null;

  Color roleColor(BuildContext context) {
    if (userRole == 'ADMIN') return AppColors.errorRed;
    if (certified) return AppColors.successGreen;
    return Colors.transparent;
  }
}
