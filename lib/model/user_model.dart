import 'json_reader.dart';

class AppUser {
  final int id;
  final String nickname;
  final String? profileImageUrl;
  final String? level;
  final String? bio;
  final DateTime? nicknameChangedAt;

  AppUser({
    required this.id,
    String? nickname,
    this.profileImageUrl,
    this.level,
    this.bio,
    this.nicknameChangedAt,
  }) : nickname = (nickname != null && nickname.isNotEmpty) ? nickname : 'guest';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json.integer('id'),
      nickname: json.strOrNull('nickname'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
      bio: json.strOrNull('bio'),
      level: json.strOrNull('level'),
      nicknameChangedAt: json.dateTimeOrNull('nicknameChangedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'profileImageUrl': profileImageUrl,
    'bio': bio,
    'level': level,
    'nicknameChangedAt': nicknameChangedAt?.toIso8601String(),
  };
}
