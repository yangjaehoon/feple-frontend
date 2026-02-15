import 'package:http/http.dart' as http;
import '../auth/token_store.dart';
import '../network/dio_client.dart';
import 'follow_response.dart';

class ArtistFollowApi {
  Future<FollowResponse> follow(int artistId) async {
    final res = await DioClient.dio.post('/artists/$artistId/follow');
    return FollowResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FollowResponse> unfollow(int artistId) async {
    final res = await DioClient.dio.delete('/artists/$artistId/follow');
    return FollowResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> isFollowed(int artistId) async {
    final res = await DioClient.dio.get('/artists/$artistId/follow');
    final v = res.data;
    if (v is bool) return v;
    return v.toString().trim() == 'true';
  }
}