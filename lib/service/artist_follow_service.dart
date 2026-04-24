import 'package:feple/model/follow_response.dart';
import 'package:feple/model/follow_status.dart';
import 'package:feple/network/dio_client.dart';

class ArtistFollowService {
  Future<FollowResponse> follow(int artistId) async {
    final res = await DioClient.dio.post('/artists/$artistId/follow');
    return FollowResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FollowResponse> unfollow(int artistId) async {
    final res = await DioClient.dio.delete('/artists/$artistId/follow');
    return FollowResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FollowStatus> getFollowStatus(int artistId) async {
    final res = await DioClient.dio.get('/artists/$artistId/follow');
    return FollowStatus.fromJson(res.data as Map<String, dynamic>);
  }
}
