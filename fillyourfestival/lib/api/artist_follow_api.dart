import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../auth/token_store.dart';
import '../network/dio_client.dart';
import 'follow_response.dart';
import 'follow_status.dart';

class ArtistFollowApi {
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