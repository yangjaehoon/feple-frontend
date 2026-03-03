import 'package:fast_app_base/model/post_model.dart';
import 'package:fast_app_base/network/dio_client.dart';

class PostService {
  static const _endpoints = {
    'HotBoard': '/posts/hot',
    'FreeBoard': '/posts/free',
    'MateBoard': '/posts/mate',
  };

  String _endpointFor(String boardType) {
    final ep = _endpoints[boardType];
    if (ep == null) throw Exception('Unknown board type: $boardType');
    return ep;
  }

  /// 게시글 목록 조회
  Future<List<Post>> fetchPosts(String boardType) async {
    final resp = await DioClient.dio.get(_endpointFor(boardType));
    final List<dynamic> jsonList = resp.data as List<dynamic>;
    return jsonList.map((json) => Post.fromJson(json)).toList();
  }

  /// 게시글 작성
  Future<void> createPost({
    required String boardType,
    required int userId,
    required String title,
    required String content,
    required String nickname,
  }) async {
    await DioClient.dio.post(
      _endpointFor(boardType),
      data: {
        'userId': userId,
        'title': title,
        'content': content,
        'nickname': nickname,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }
}
