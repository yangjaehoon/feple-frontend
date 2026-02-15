class FollowStatus {
  final bool followed;
  final int followerCount;

  FollowStatus({required this.followed, required this.followerCount});

  factory FollowStatus.fromJson(Map<String, dynamic> json) {
    return FollowStatus(
      followed: json['followed'] == true,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    );
  }
}