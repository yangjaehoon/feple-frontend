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

  /// 게시글 작성 (userId는 서버에서 JWT로 추출)
  Future<void> createPost({
    required String boardType,
    required String title,
    required String content,
  }) async {
    await DioClient.dio.post(
      _endpointFor(boardType),
      data: {
        'title': title,
        'content': content,
      },
    );
  }
}
