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
      id: (json['id'] as num).toInt(),
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      level: json['level'] is String ? json['level'] as String : null,
      nicknameChangedAt: json['nicknameChangedAt'] is String
          ? DateTime.tryParse(json['nicknameChangedAt'] as String)
          : null,
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
