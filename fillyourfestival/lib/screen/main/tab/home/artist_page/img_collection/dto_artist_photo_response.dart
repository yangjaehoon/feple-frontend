class ArtistPhotoResponse {
  final int photoId;
  final String url;
  final int uploaderUserId;
  final DateTime createdAt;
  final String title;
  final String description;

  ArtistPhotoResponse({
    required this.photoId,
    required this.url,
    required this.uploaderUserId,
    required this.createdAt,
    required this.title,
    required this.description,
  });

  factory ArtistPhotoResponse.fromJson(Map<String, dynamic> json) {
    return ArtistPhotoResponse(
      photoId: json['photoId'],
      url: json['url'],
      uploaderUserId: json['uploaderUserId'],
      createdAt: DateTime.parse(json['createdAt']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}