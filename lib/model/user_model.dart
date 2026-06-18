class User {
  final int id;
  final String nickname;
  final String? profileImageUrl;
  final int level;
  final String? bio;

  User({
    required this.id,
    String? nickname,
    this.profileImageUrl,
    this.level = 0,
    this.bio,
  }) : nickname = (nickname != null && nickname.isNotEmpty) ? nickname : 'guest';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      level: json['level'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'profileImageUrl': profileImageUrl,
    'bio': bio,
    'level': level,
  };
}
