import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../auth/keys.dart';


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


Future<String> getApiKey() async {
  try {
    final secret =
    await SecretLoader(secretPath: 'lib/auth/secrets.json').load();
    return secret.apikey;
  } catch (e) {
    // 예외 처리: API 키를 가져오지 못한 경우
    print('Error getting API key: $e');
    return ''; // 빈 문자열 또는 다른 기본값을 반환
  }
}
