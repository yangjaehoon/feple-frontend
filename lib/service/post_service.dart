import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/model/post_draft.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/network/dio_client.dart';

export 'package:feple/model/post_draft.dart';

class PostService {
  static const _defaultPageSize = 20;

  static const _endpoints = {
    BoardTypes.hot: '/posts/popular',
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
    final data = response.data;
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['content'] is List) {
      list = data['content'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 게시글 목록 조회 (hot은 List 직접 반환, free/mate는 CursorPage에서 content 추출)
  Future<List<Post>> fetchPosts(String boardType) async {
    if (BoardTypes.isPaginated(boardType)) {
      final page = await fetchPostsPage(boardType);
      return page.content;
    }
    return _fetchPostList(_endpointFor(boardType));
  }

  static const postImagePresignEndpoint = '/posts/image-upload-url';

  /// 게시글 커서 페이지 조회 (free/mate 전용)
  Future<PostCursorPage> fetchPostsPage(String boardType, {int? cursor, int size = _defaultPageSize, String sort = 'latest'}) =>
      _fetchCursorPage(_endpointFor(boardType), cursor: cursor, size: size, sort: sort);

  Future<void> _createPost(String endpoint, PostDraft draft) =>
      withBannedWordCheck(() => DioClient.dio.post(endpoint, data: {
            'title': draft.title,
            'content': draft.content,
            'anonymous': draft.anonymous,
            'imageUrls': draft.imageObjectKeys,
          }));

  /// 게시글 단건 조회
  Future<Post> fetchPost(int postId) async {
    final response = await DioClient.dio.get('/posts/$postId');
    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  /// 게시글 좋아요·스크랩 수 조회 (query only)
  Future<({int likeCount, int scrapCount})> fetchCounts(int postId) async {
    final response = await DioClient.dio.get('/posts/$postId');
    return (
      likeCount: (response.data['likeCount'] as num?)?.toInt() ?? 0,
      scrapCount: (response.data['scrapCount'] as num?)?.toInt() ?? 0,
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
  Future<void> createPost({required String boardType, required PostDraft draft}) =>
      _createPost(_endpointFor(boardType), draft);

  /// 아티스트 게시판 페이지 조회
  Future<PostCursorPage> fetchArtistPostsPage(int artistId, {int? cursor, int size = _defaultPageSize}) =>
      _fetchCursorPage('/posts/artist/$artistId', cursor: cursor, size: size);

  /// 아티스트 게시판 목록 조회
  Future<List<Post>> fetchArtistPosts(int artistId) =>
      _fetchPostList('/posts/artist/$artistId');

  /// 아티스트 게시판 글 작성
  Future<void> createArtistPost({required int artistId, required PostDraft draft}) =>
      _createPost('/posts/artist/$artistId', draft);

  /// 페스티벌 게시판 페이지 조회
  Future<PostCursorPage> fetchFestivalPostsPage(int festivalId, {int? cursor, int size = _defaultPageSize}) =>
      _fetchCursorPage('/posts/festival/$festivalId', cursor: cursor, size: size);

  /// 페스티벌 게시판 글 작성
  Future<void> createFestivalPost({required int festivalId, required PostDraft draft}) =>
      _createPost('/posts/festival/$festivalId', draft);

  /// 페스티벌 인기 글 조회 (likeCount 내림차순, 전체 게시판)
  Future<List<Post>> fetchFestivalPopularPosts(int festivalId) =>
      _fetchPostList('/posts/festival/$festivalId/popular');

  /// 동행구하기 게시판 페이지 조회
  Future<PostCursorPage> fetchFestivalCompanionPostsPage(int festivalId, {int? cursor, int size = _defaultPageSize}) =>
      _fetchCursorPage('/posts/festival/$festivalId/companion', cursor: cursor, size: size);

  /// 동행구하기 게시판 글 작성
  Future<void> createFestivalCompanionPost({required int festivalId, required PostDraft draft}) =>
      _createPost('/posts/festival/$festivalId/companion', draft);

  /// 티켓양도 게시판 페이지 조회
  Future<PostCursorPage> fetchFestivalTicketPostsPage(int festivalId, {int? cursor, int size = _defaultPageSize}) =>
      _fetchCursorPage('/posts/festival/$festivalId/ticket', cursor: cursor, size: size);

  /// 티켓양도 게시판 글 작성
  Future<void> createFestivalTicketPost({required int festivalId, required PostDraft draft}) =>
      _createPost('/posts/festival/$festivalId/ticket', draft);

  /// 게시글 삭제
  Future<void> deletePost(int postId) => DioClient.dio.delete('/posts/$postId');

  /// 게시글 수정
  Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
    List<String> imageObjectKeys = const [],
  }) => withBannedWordCheck(() => DioClient.dio.put('/posts/$postId', data: {
        'title': title,
        'content': content,
        'imageUrls': imageObjectKeys,
      }));

  Future<void> incrementPostView(int postId) =>
      DioClient.dio.post('/posts/$postId/view');

  Future<PostCursorPage> _fetchCursorPage(String endpoint, {int? cursor, int size = _defaultPageSize, String? sort}) async {
    final response = await DioClient.dio.get(endpoint, queryParameters: {
      'cursor': ?cursor,
      'size': size,
      'sort': ?sort,
    });
    return PostCursorPage.fromJson(response.data as Map<String, dynamic>);
  }

  /// 게시판 내 키워드 검색
  Future<List<Post>> searchInBoard(String keyword, String boardType) async {
    final response = await DioClient.dio.get('/posts/search', queryParameters: {
      'keyword': keyword,
      'boardType': boardType,
    });
    return response.toModelList(Post.fromJson);
  }
}
