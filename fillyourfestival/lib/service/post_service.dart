import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fast_app_base/model/post_model.dart';

import '../config.dart';

class PostService {

  Future<List<Post>> fetchFreePosts() async {
    final url = Uri.parse('$baseUrl/posts/free');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // JSON 파싱: 리스트 형태의 JSON 배열로부터 List<Post> 생성
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }
}
