import 'package:feple/model/blocked_user_model.dart';
import 'package:feple/network/dio_client.dart';

class BlockService {
  Future<void> blockUser(int targetUserId) =>
      DioClient.dio.post('/users/$targetUserId/block');

  Future<void> unblockUser(int targetUserId) =>
      DioClient.dio.delete('/users/$targetUserId/block');

  Future<List<BlockedUserModel>> getBlockedUsers() async {
    final response = await DioClient.dio.get('/users/blocked');
    return response.toModelList(BlockedUserModel.fromJson);
  }
}
