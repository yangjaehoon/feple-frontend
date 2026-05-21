import 'package:feple/model/follow_status.dart';
import 'package:feple/network/dio_client.dart';

class ArtistFollowService {
  Future<void> follow(int artistId) =>
      DioClient.dio.post('/artists/$artistId/follow');

  Future<void> unfollow(int artistId) =>
      DioClient.dio.delete('/artists/$artistId/follow');

  Future<FollowStatus> getFollowStatus(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/follow');
    return FollowStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Set<int>> getFollowingIds(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/following');
    return (response.data as List)
        .map((a) => (a['id'] as num).toInt())
        .toSet();
  }
}
