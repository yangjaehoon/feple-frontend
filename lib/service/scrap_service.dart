import 'package:feple/model/post_model.dart';
import 'package:feple/network/dio_client.dart';

class ScrapService {
  /// 스크랩 토글 → 현재 스크랩 상태 반환
  Future<bool> toggleScrap(int postId) async {
    final resp = await DioClient.dio.post('/posts/$postId/scrap');
    return resp.data as bool;
  }

  /// 특정 게시글 스크랩 여부 조회
  Future<bool> isScraped(int postId) async {
    final resp = await DioClient.dio.get('/posts/$postId/scraped');
    return resp.data as bool;
  }

  /// 내 스크랩 목록 조회
  Future<List<Post>> fetchMyScraps() async {
    final resp = await DioClient.dio.get('/posts/my/scrapped');
    return (resp.data as List<dynamic>)
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
