class ArtistPhotoResponse {
  final int photoId;
  final String url;
  final int uploaderUserId;
  final DateTime createdAt;
  final String title;
  final String description;
  final int likecount;
  final bool isLiked;


  ArtistPhotoResponse({
    required this.photoId,
    required this.url,
    required this.uploaderUserId,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.likecount,
    required this.isLiked,
  });

  factory ArtistPhotoResponse.fromJson(Map<String, dynamic> json) {
    return ArtistPhotoResponse(
      photoId: json['photoId'],
      url: json['url'],
      uploaderUserId: json['uploaderUserId'],
      createdAt: DateTime.parse(json['createdAt']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      likecount: json['likecount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }
}