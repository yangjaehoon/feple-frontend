/// 팔로우한 아티스트 모델 (홈, 마이페이지 등에서 공통 사용)
class FollowedArtist {
  final int id;
  final String name;
  final String? profileImageUrl;
  final String? genre;
  final int followerCount;

  const FollowedArtist({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.genre,
    this.followerCount = 0,
  });

  factory FollowedArtist.fromJson(Map<String, dynamic> json) {
    return FollowedArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      genre: json['genre'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    );
  }
}
