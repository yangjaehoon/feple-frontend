import 'package:feple/network/dio_client.dart';

class NotificationService {
  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final res = await DioClient.dio.get('/notifications/my');
    return (res.data as List).cast<Map<String, dynamic>>();
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
