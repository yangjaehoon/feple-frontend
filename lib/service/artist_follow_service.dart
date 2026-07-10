import 'package:feple/model/follow_status.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/user_service.dart';

class ArtistFollowService {
  final UserService userService;

  ArtistFollowService({required this.userService});

  Future<void> follow(int artistId) =>
      DioClient.dio.post('/artists/$artistId/follow');

  Future<void> unfollow(int artistId) =>
      DioClient.dio.delete('/artists/$artistId/follow');

  Future<FollowStatus> getFollowStatus(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/follow');
    return FollowStatus.fromJson(response.data as Map<String, dynamic>);
  }

  // UserService.fetchFollowingArtists와 같은 /users/{id}/following 엔드포인트를
  // 각자 파싱하던 중복을 없애고 하나의 결과에서 파생시킴
  Future<Set<int>> fetchFollowingIds(int userId) async {
    final artists = await userService.fetchFollowingArtists(userId);
    return artists.map((a) => a.id).toSet();
  }

  Future<Set<String>> fetchFollowedArtistNames(int userId) async {
    final artists = await userService.fetchFollowingArtists(userId);
    return artists.map((a) => a.name).where((n) => n.isNotEmpty).toSet();
  }
}
