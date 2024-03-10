import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fast_app_base/auth/keys.dart';

import '../../../../../auth/get_api_key.dart';



Future<List<Map<String,String>>> fetchMostViewedNewsThumbnail(String artistName) async {
  final apiKey = await getApiKey('youtube_api_key');
  final query = '$artistName 페스티벌';
  List<Map<String,String>> youtubeInfo = [];

  final url = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&order=relevance&key=$apiKey',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['items'] != null) {
      for (final item in data['items']) {
        final videoId = item['id']['videoId'];
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
        final videoTitle = item['snippet']['title'];
        youtubeInfo.add({
          'thumbnailUrl': thumbnailUrl,
          'videoTitle': videoTitle,
        });
        //youtubeInfo.add(videoTitle);
        //setState(() {});
      }
    }
  }
  return youtubeInfo;
}

