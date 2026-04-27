import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../../auth/get_api_key.dart';



Future<List<Map<String,String>>> fetchMostViewedNewsThumbnail(String artistName) async {
  final apiKey = await getApiKey('youtube_api_key');
  final query = '$artistName 페스티벌';
  final videoDurationParam = 'short';
  final videoRatioParam = '9:16';
  List<Map<String,String>> youtubeInfo = [];

  final url = Uri.parse(
    //'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&order=relevance&videoDuration=short&key=$apiKey',
      'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&videoDuration=$videoDurationParam&videoRatio=$videoRatioParam&key=$apiKey'
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['items'] != null) {
      for (final item in data['items']) {
        final videoId = item['id']['videoId'];
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
        //final videoTitle = item['snippet']['title'];
        youtubeInfo.add({
          'thumbnailUrl': thumbnailUrl,
          //'videoTitle': videoTitle,
        });
      }
    }
  }
  return youtubeInfo;
}

