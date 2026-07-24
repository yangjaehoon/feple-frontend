import 'package:feple/network/dio_client.dart';

class FestivalInteractionService {
  Future<bool> isLiked(int festivalId) =>
      _fetchBool('/festivals/$festivalId/liked');

  Future<void> toggleLike(int festivalId) =>
      DioClient.dio.post('/festivals/$festivalId/like');

  Future<bool> isAttending(int festivalId) =>
      _fetchBool('/festivals/$festivalId/attending');

  Future<void> toggleAttending(int festivalId) =>
      DioClient.dio.post('/festivals/$festivalId/attending');

  Future<bool> _fetchBool(String endpoint) async {
    final response = await DioClient.dio.get(endpoint);
    return response.data as bool;
  }
}
