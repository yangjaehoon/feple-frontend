import 'package:feple/common/constant/board_types.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/network/dio_client.dart';

class PostService {
  static const _endpoints = {
    BoardTypes.hot: '/posts/hot',
    BoardTypes.free: '/posts/free',
    BoardTypes.mate: '/posts/mate',
  };

  String _endpointFor(String boardType) {
    final ep = _endpoints[boardType];
    if (ep == null) throw Exception('Unknown board type: $boardType');
    return ep;
  }

  Future<List<Post>> _fetchPostList(String endpoint) async {
    final resp = await DioClient.dio.get(endpoint);
    return (resp.data as List<dynamic>).map((json) => Post.fromJson(json)).toList();
  }

  /// 게시글 목록 조회
  Future<List<Post>> fetchPosts(String boardType) =>
      _fetchPostList(_endpointFor(boardType));

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

  /// 아티스트 게시판 목록 조회
  Future<List<Post>> fetchArtistPosts(int artistId) =>
      _fetchPostList('/posts/artist/$artistId');

  /// 아티스트 게시판 글 작성
  Future<void> createArtistPost({
    required int artistId,
    required String title,
    required String content,
  }) async {
    await DioClient.dio.post(
      '/posts/artist/$artistId',
      data: {
        'title': title,
        'content': content,
      },
    );
  }

  /// 페스티벌 게시판 목록 조회
  Future<List<Post>> fetchFestivalPosts(int festivalId) =>
      _fetchPostList('/posts/festival/$festivalId');

  /// 페스티벌 게시판 글 작성
  Future<void> createFestivalPost({
    required int festivalId,
    required String title,
    required String content,
  }) async {
    await DioClient.dio.post(
      '/posts/festival/$festivalId',
      data: {
        'title': title,
        'content': content,
      },
    );
  }
}
