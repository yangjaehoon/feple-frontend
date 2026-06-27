class ArtistPhotoResponse {
  final int photoId;
  final String url;
  // 익명 업로드 시 타인에게는 null로 반환됨; 본인 글은 항상 반환
  final int? uploaderUserId;
  // 익명 업로드 시 "익명" 반환
  final String uploaderNickname;
  final DateTime createdAt;
  final String title;
  final String description;
  final int likeCount;
  final bool isLiked;
  final bool isAnonymous;

  ArtistPhotoResponse({
    required this.photoId,
    required this.url,
    required this.uploaderUserId,
    required this.uploaderNickname,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.likeCount,
    required this.isLiked,
    required this.isAnonymous,
  });

  ArtistPhotoResponse copyWith({
    int? photoId,
    String? url,
    int? uploaderUserId,
    String? uploaderNickname,
    DateTime? createdAt,
    String? title,
    String? description,
    int? likeCount,
    bool? isLiked,
    bool? isAnonymous,
  }) {
    return ArtistPhotoResponse(
      photoId: photoId ?? this.photoId,
      url: url ?? this.url,
      uploaderUserId: uploaderUserId ?? this.uploaderUserId,
      uploaderNickname: uploaderNickname ?? this.uploaderNickname,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  factory ArtistPhotoResponse.fromJson(Map<String, dynamic> json) {
    return ArtistPhotoResponse(
      photoId: (json['photoId'] as num).toInt(),
      url: json['url'] as String,
      uploaderUserId: (json['uploaderUserId'] as num?)?.toInt(),
      uploaderNickname: json['uploaderNickname'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
    );
  }
}
