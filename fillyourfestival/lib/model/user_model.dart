class User {
  final int? id;
  final String? nickname;
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
      this.nickname,
      required this.uid,
      required this.profileImageUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nickname: json['nickname'],
      uid: json['uid'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
