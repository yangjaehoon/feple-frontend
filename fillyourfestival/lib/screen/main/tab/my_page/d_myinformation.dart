class MyInfo {
  late String nickname;
  late List<String> followartist;
  late int postnum, commentnum, bookmarknum, level;
  MyInfo({required this.nickname, required this.followartist, required this.postnum, required this.commentnum,
    required this.bookmarknum, required this.level});

  factory MyInfo.fromJson(Map<String, dynamic> json) {
    return MyInfo(
      nickname: json['nickname'],
      followartist: json['followartist'],
      postnum: json['postnum'],
      commentnum: json['commentnum'],
      bookmarknum: json['bookmarknum'],
      level: json['level'],
    );
  }
}
