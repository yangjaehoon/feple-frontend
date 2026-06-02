import 'package:feple/model/notification_model.dart';
import 'package:feple/network/dio_client.dart';

class NotificationService {
  Future<List<NotificationModel>> getMyNotifications() async {
    final response = await DioClient.dio.get('/notifications/my');
    return response.toModelList(NotificationModel.fromJson);
  }

  Future<int> getUnreadCount() async {
    final response = await DioClient.dio.get('/notifications/my/unread-count');
    return (response.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) async {
    await DioClient.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await DioClient.dio.patch('/notifications/my/read-all');
  }
}
