class SongModel {
  final int id;
  final String title;
  final String youtubeVideoId;
  final String? thumbnailUrl;
  final String youtubeUrl;

  const SongModel({
    required this.id,
    required this.title,
    required this.youtubeVideoId,
    this.thumbnailUrl,
    required this.youtubeUrl,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      youtubeVideoId: json['youtubeVideoId'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String? ??
          'https://music.youtube.com/watch?v=${json['youtubeVideoId']}',
    );
  }
}
