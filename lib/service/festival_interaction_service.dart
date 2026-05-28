import 'package:feple/network/dio_client.dart';

class FestivalInteractionService {
  Future<bool> isLiked(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/liked');
    return response.data as bool;
  }

  Future<void> toggleLike(int festivalId) =>
      DioClient.dio.post('/festivals/$festivalId/like');

  Future<bool> isAttending(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/attending');
    return response.data as bool;
  }

  Future<bool> toggleAttending(int festivalId) async {
    final response = await DioClient.dio.post('/festivals/$festivalId/attending');
    return response.data as bool;
  }
}
