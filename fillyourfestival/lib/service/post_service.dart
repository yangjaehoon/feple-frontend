import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fast_app_base/model/post_model.dart';

import '../config.dart';

class PostService {

  Future<List<Post>> fetchPosts(String boardType) async {
    String endpoint;
    switch (boardType) {
      case 'HotBoard':
        endpoint = 'posts/hot';
        break;
      case 'FreeBoard':
        endpoint = 'posts/free';
        break;
      case 'MateBoard':
        endpoint = 'posts/mate';
        break;
    // 추가 게시판 타입이 있으면 여기 추가
      default:
        throw Exception('Unknown board type');
    }

    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('$boardType 데이터를 불러오는데 실패했습니다.');
    }
  }
}
