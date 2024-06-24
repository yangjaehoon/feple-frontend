class User {
  int? id;
  String? nickname;
  String uid;

  int? post_Num;
  int? commnet_Num;
  int? bookmark_Num;

  int? level;

  //String? email;
  //String? password;

  User({this.id, this.nickname, required this.uid});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nickname: json['nickname'],
      uid: json['uid'],
    );
  }
}
