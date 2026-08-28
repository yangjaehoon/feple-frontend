import 'date_format.dart';
import 'json_reader.dart';

class ArtistPhoto {
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

  ArtistPhoto({
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

  ArtistPhoto copyWith({
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
    return ArtistPhoto(
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

  factory ArtistPhoto.fromJson(Map<String, dynamic> json) {
    return ArtistPhoto(
      photoId: json.integer('photoId'),
      url: json.str('url'),
      uploaderUserId: json.intOrNull('uploaderUserId'),
      uploaderNickname: json.str('uploaderNickname'),
      createdAt: parseServerDateTime(json.strOrNull('createdAt')),
      title: json.str('title'),
      description: json.str('description'),
      likeCount: json.integer('likeCount'),
      isLiked: json.boolean('isLiked'),
      isAnonymous: json.boolean('isAnonymous'),
    );
  }
}
