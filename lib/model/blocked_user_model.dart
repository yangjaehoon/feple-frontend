class BlockedUserModel {
  final int userId;
  final String nickname;
  final String? profileImageUrl;

  const BlockedUserModel({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      userId: json['userId'] as int,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
