class Artist {
  final int id;
  final String name;
  final String nameEn;
  final String genre;
  final String profileImageUrl;
  final int followerCount;

  const Artist({
    required this.id,
    required this.name,
    this.nameEn = '',
    required this.genre,
    required this.profileImageUrl,
    required this.followerCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String,
      nameEn: (json['nameEn'] as String?) ?? '',
      genre: json['genre'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      followerCount: (json['followerCount'] ?? 0) as int,
    );
  }

  String displayName(bool isEnglish) =>
      isEnglish && nameEn.isNotEmpty ? nameEn : name;
}