class User {
  final int id;
  String nickname;

  //final String uid;

  final String profileImageUrl;

  int? postNum;
  int? commentNum;
  int? bookmarkNum;

  int? level;

  //String? email;
  //String? password;

  User(
      {required this.id,
      String? nickname,
      //required this.uid,
      required this.profileImageUrl})
      : nickname =
            (nickname != null && nickname.isNotEmpty) ? nickname : 'guest';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      nickname: json['nickname'] as String?,
      //uid: json['uid'],
      profileImageUrl: json['profileImageUrl'] as String,
    );
  }
}
