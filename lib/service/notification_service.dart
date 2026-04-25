import 'package:feple/model/notification_model.dart';
import 'package:feple/network/dio_client.dart';

class NotificationService {
  Future<List<NotificationModel>> getMyNotifications() async {
    final res = await DioClient.dio.get('/notifications/my');
    return (res.data as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final res = await DioClient.dio.get('/notifications/my/unread-count');
    return (res.data['count'] as num).toInt();
  }

  Future<void> markRead(int id) async {
    await DioClient.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await DioClient.dio.patch('/notifications/my/read-all');
  }
}
