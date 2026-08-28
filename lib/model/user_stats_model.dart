import 'json_reader.dart';

class UserStats {
  final int postCount;
  final int commentCount;
  final int certificationCount;
  final int scrapCount;
  final int likedPostCount;

  const UserStats({
    required this.postCount,
    required this.commentCount,
    required this.certificationCount,
    required this.scrapCount,
    required this.likedPostCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        postCount: json.integer('postCount'),
        commentCount: json.integer('commentCount'),
        certificationCount: json.integer('certificationCount'),
        scrapCount: json.integer('scrapCount'),
        likedPostCount: json.integer('likedPostCount'),
      );
}
