import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fast_app_base/auth/keys.dart';

import '../../../../../auth/get_api_key.dart';

Future<List<String>> fetchMostViewedNewsThumbnail() async {
  final apiKey = await getApiKey();
  final query = '한요한 페스티벌';
  List<String> thumbnails = [];

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
        thumbnails.add(thumbnailUrl);
        //setState(() {});
      }
    }
  }
  return thumbnails;
}
