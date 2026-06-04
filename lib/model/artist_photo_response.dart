class ArtistPhotoResponse {
  final int photoId;
  final String url;
  final int uploaderUserId;
  final DateTime createdAt;
  final String title;
  final String description;
  final int likeCount;
  final bool isLiked;


  ArtistPhotoResponse({
    required this.photoId,
    required this.url,
    required this.uploaderUserId,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.likeCount,
    required this.isLiked,
  });

  factory ArtistPhotoResponse.fromJson(Map<String, dynamic> json) {
    return ArtistPhotoResponse(
      photoId: (json['photoId'] as num).toInt(),
      url: json['url'] as String,
      uploaderUserId: (json['uploaderUserId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }
}