import 'package:feple/model/post_model.dart';
import 'package:feple/network/dio_client.dart';

class ScrapService {
  /// 스크랩 토글 (command only — CQS. 호출자에서 낙관적 업데이트 사용)
  Future<void> toggleScrap(int postId) =>
      DioClient.dio.post('/posts/$postId/scrap');

  /// 특정 게시글 스크랩 여부 조회
  Future<bool> isScraped(int postId) async {
    final response = await DioClient.dio.get('/posts/$postId/scraped');
    return response.data as bool;
  }

  /// 내 스크랩 목록 조회
  Future<List<Post>> fetchMyScraps() async {
    final response = await DioClient.dio.get('/posts/scrapped');
    return (response.data as List<dynamic>)
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
