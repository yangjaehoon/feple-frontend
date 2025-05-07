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
      required String nickname,
      //required this.uid,
      required this.profileImageUrl})
      : nickname = nickname.isNotEmpty ? nickname : 'guest';

  factory User.fromJson(Map<String, dynamic> json) {

    final rawNick = (json['nickname'] as String?)?.trim() ?? '';

    return User(
      id: json['id'],
      nickname: rawNick,
      //uid: json['uid'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
