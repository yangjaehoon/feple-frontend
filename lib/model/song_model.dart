import 'json_reader.dart';

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
    final videoId = json.str('youtubeVideoId');
    final url = json.str('youtubeUrl');
    return SongModel(
      id: json.integer('id'),
      title: json.str('title'),
      youtubeVideoId: videoId,
      thumbnailUrl: json.strOrNull('thumbnailUrl'),
      youtubeUrl: url.isNotEmpty ? url : _urlFromVideoId(videoId),
      festivalCount: json.integer('festivalCount'),
    );
  }

  static String _urlFromVideoId(String videoId) =>
      'https://music.youtube.com/watch?v=$videoId';
}
