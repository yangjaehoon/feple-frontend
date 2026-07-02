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
        postCount: json['postCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        certificationCount: json['certificationCount'] as int? ?? 0,
        scrapCount: json['scrapCount'] as int? ?? 0,
        likedPostCount: json['likedPostCount'] as int? ?? 0,
      );
}
