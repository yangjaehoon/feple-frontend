import 'json_reader.dart';

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
      userId: json.integer('userId'),
      nickname: json.str('nickname'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
    );
  }
}
