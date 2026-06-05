class User {
  final int id;
  String nickname;

  //final String uid;

  final String? profileImageUrl;

  int? postNum;
  int? commentNum;
  int? bookmarkNum;

  int level;

  final String? bio;

  //String? email;
  //String? password;

  User(
      {required this.id,
      String? nickname,
      //required this.uid,
      this.profileImageUrl,
      this.level = 0,
      this.bio})
      : nickname =
            (nickname != null && nickname.isNotEmpty) ? nickname : 'guest';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
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
