class SongModel {
  final int id;
  final String title;
  final String youtubeVideoId;
  final String? thumbnailUrl;
  final String youtubeUrl;
  final int festivalCount;

  const SongModel({
    required this.id,
    required this.title,
    required this.youtubeVideoId,
    this.thumbnailUrl,
    required this.youtubeUrl,
    this.festivalCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'youtubeVideoId': youtubeVideoId,
        'thumbnailUrl': thumbnailUrl,
        'youtubeUrl': youtubeUrl,
        'festivalCount': festivalCount,
      };

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final videoId = json['youtubeVideoId'] as String;
    return SongModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      youtubeVideoId: videoId,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String? ?? _urlFromVideoId(videoId),
      festivalCount: (json['festivalCount'] as num?)?.toInt() ?? 0,
    );
  }

  static String _urlFromVideoId(String videoId) =>
      'https://music.youtube.com/watch?v=$videoId';
}
