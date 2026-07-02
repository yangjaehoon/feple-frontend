class FollowedArtist {
  final int id;
  final String name;
  final String nameEn;
  final String? profileImageUrl;
  final String? genre;
  final int followerCount;

  const FollowedArtist({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.profileImageUrl,
    this.genre,
    this.followerCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'profileImageUrl': profileImageUrl,
        'genre': genre,
        'followerCount': followerCount,
      };

  factory FollowedArtist.fromJson(Map<String, dynamic> json) {
    return FollowedArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      nameEn: (json['nameEn'] as String?) ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      genre: json['genre'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    );
  }

  List<String> get genres {
    final g = genre;
    if (g == null || g.isEmpty) return const [];
    return g.split(', ');
  }

  String displayName(bool isEnglish) =>
      isEnglish && nameEn.isNotEmpty ? nameEn : name;
}
