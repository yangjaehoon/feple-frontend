class FollowResponse {
  final bool followed;
  final int followerCount;

  FollowResponse({required this.followed, required this.followerCount});

  factory FollowResponse.fromJson(Map<String, dynamic> json) {
    return FollowResponse(
      followed: json['followed'] as bool,
      followerCount: json['followerCount'] as int,
    );
  }
}