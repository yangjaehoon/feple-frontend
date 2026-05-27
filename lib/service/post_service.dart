import 'package:dio/dio.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
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
    final response = await DioClient.dio.get(endpoint);
    return (response.data as List<dynamic>).map((json) => Post.fromJson(json)).toList();
  }

  /// 게시글 목록 조회 (hot은 페이지네이션 미지원)
  Future<List<Post>> fetchPosts(String boardType) =>
      _fetchPostList(_endpointFor(boardType));

  static const postImagePresignEndpoint = '/posts/image-upload-url';

  /// 게시글 페이지 조회 (free/mate 전용)
  Future<List<Post>> fetchPostsPage(String boardType, {int page = 0, int size = 20, String sort = 'latest'}) async {
    final endpoint = _endpointFor(boardType);
    final response = await DioClient.dio.get(endpoint, queryParameters: {'page': page, 'size': size, 'sort': sort});
    return (response.data as List<dynamic>).map((json) => Post.fromJson(json)).toList();
  }

  Future<void> _createPost(String endpoint, String title, String content, {bool anonymous = false, String? imageObjectKey}) async {
    try {
      await DioClient.dio.post(endpoint, data: {
        'title': title,
        'content': content,
        'anonymous': anonymous,
        if (imageObjectKey != null) 'imageObjectKey': imageObjectKey,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        String msg = '';
        if (data is Map) {
          msg = (data['message'] as String?) ?? '';
        } else if (data is String) {
          msg = data;
        }
        if (msg.startsWith('title:')) throw const BannedWordException('title');
        if (msg.startsWith('content:')) throw const BannedWordException('content');
        if (msg.contains('금칙어')) throw const BannedWordException('content');
      }
      rethrow;
    }
  }

  /// 게시글 좋아요·스크랩 수 조회 (query only)
  Future<({int likeCount, int scrapCount})> fetchCounts(int postId) async {
    final response = await DioClient.dio.get('/posts/$postId');
    return (
      likeCount: (response.data['likeCount'] as num).toInt(),
      scrapCount: (response.data['scrapCount'] as num).toInt(),
    );
  }

  /// 내가 이 게시글을 좋아요 했는지 조회 (query only)
  Future<bool> isLiked(int postId) async {
    final response = await DioClient.dio.get('/posts/$postId/liked');
    return response.data as bool;
  }

  /// 좋아요 토글 (command only — CQS)
  Future<void> toggleLike(int postId) =>
      DioClient.dio.post('/posts/$postId/like');

  /// 게시글 작성 (userId는 서버에서 JWT로 추출)
  Future<void> createPost({
    required String boardType,
    required String title,
    required String content,
    bool anonymous = false,
    String? imageObjectKey,
  }) =>
      _createPost(_endpointFor(boardType), title, content, anonymous: anonymous, imageObjectKey: imageObjectKey);

  /// 아티스트 게시판 목록 조회
  Future<List<Post>> fetchArtistPosts(int artistId) =>
      _fetchPostList('/posts/artist/$artistId');

  /// 아티스트 게시판 글 작성
  Future<void> createArtistPost({
    required int artistId,
    required String title,
    required String content,
    bool anonymous = false,
    String? imageObjectKey,
  }) =>
      _createPost('/posts/artist/$artistId', title, content, anonymous: anonymous, imageObjectKey: imageObjectKey);

  /// 페스티벌 게시판 목록 조회
  Future<List<Post>> fetchFestivalPosts(int festivalId) =>
      _fetchPostList('/posts/festival/$festivalId');

  /// 페스티벌 게시판 글 작성
  Future<void> createFestivalPost({
    required int festivalId,
    required String title,
    required String content,
    bool anonymous = false,
    String? imageObjectKey,
  }) =>
      _createPost('/posts/festival/$festivalId', title, content, anonymous: anonymous, imageObjectKey: imageObjectKey);

  /// 페스티벌 인기 글 조회 (likeCount 내림차순, 전체 게시판)
  Future<List<Post>> fetchFestivalPopularPosts(int festivalId) =>
      _fetchPostList('/posts/festival/$festivalId/popular');

  /// 동행구하기 게시판 목록 조회
  Future<List<Post>> fetchFestivalCompanionPosts(int festivalId) =>
      _fetchPostList('/posts/festival/$festivalId/companion');

  /// 동행구하기 게시판 글 작성
  Future<void> createFestivalCompanionPost({
    required int festivalId,
    required String title,
    required String content,
    bool anonymous = false,
    String? imageObjectKey,
  }) =>
      _createPost('/posts/festival/$festivalId/companion', title, content, anonymous: anonymous, imageObjectKey: imageObjectKey);

  /// 티켓양도 게시판 목록 조회
  Future<List<Post>> fetchFestivalTicketPosts(int festivalId) =>
      _fetchPostList('/posts/festival/$festivalId/ticket');

  /// 티켓양도 게시판 글 작성
  Future<void> createFestivalTicketPost({
    required int festivalId,
    required String title,
    required String content,
    bool anonymous = false,
    String? imageObjectKey,
  }) =>
      _createPost('/posts/festival/$festivalId/ticket', title, content, anonymous: anonymous, imageObjectKey: imageObjectKey);

  /// 게시글 삭제
  Future<void> deletePost(int postId) => DioClient.dio.delete('/posts/$postId');

  /// 게시글 수정
  Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
  }) =>
      DioClient.dio.put('/posts/$postId', data: {'title': title, 'content': content});

  /// 게시판 내 키워드 검색
  Future<List<Post>> searchInBoard(String keyword, String boardType) async {
    final response = await DioClient.dio.get('/posts/search', queryParameters: {
      'keyword': keyword,
      'boardType': boardType,
    });
    return (response.data as List).map((j) => Post.fromJson(j as Map<String, dynamic>)).toList();
  }
}
