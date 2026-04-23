/// 팔로우한 아티스트 모델 (홈, 검색 등에서 공통 사용)
class FollowedArtist {
  final int id;
  final String name;
  final String? profileImageUrl;

  const FollowedArtist({
    required this.id,
    required this.name,
    this.profileImageUrl,
  });

  factory FollowedArtist.fromJson(Map<String, dynamic> json) {
    return FollowedArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
