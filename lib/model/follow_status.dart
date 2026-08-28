import 'json_reader.dart';

class FollowStatus {
  final bool followed;
  final int followerCount;

  FollowStatus({required this.followed, required this.followerCount});

  factory FollowStatus.fromJson(Map<String, dynamic> json) {
    return FollowStatus(
      followed: json.boolean('followed'),
      followerCount: json.integer('followerCount'),
    );
  }
}
