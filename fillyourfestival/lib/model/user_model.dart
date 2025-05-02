class User {
  final int? id;
  String nickname;
  final String uid;

  final String profileImageUrl;

  int? post_Num;
  int? commnet_Num;
  int? bookmark_Num;

  int? level;

  //String? email;
  //String? password;

  User(
      {this.id,
      String? nickname,
      required this.uid,
      required this.profileImageUrl
      }): nickname = (nickname != null && nickname.isNotEmpty)
        ? nickname : 'guest';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nickname: json['nickname'],
      uid: json['uid'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
