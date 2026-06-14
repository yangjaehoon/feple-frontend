import 'package:feple/model/notification_model.dart';
import 'package:feple/network/dio_client.dart';

class NotificationPage {
  final List<NotificationModel> items;
  final bool hasMore;

  const NotificationPage({required this.items, required this.hasMore});
}

class NotificationService {
  static const int _pageSize = 20;

  Future<NotificationPage> fetchPage(int page) async {
    final response = await DioClient.dio.get(
      '/notifications/my',
      queryParameters: {'page': page, 'size': _pageSize},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['content'] as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pageInfo = data['page'] as Map<String, dynamic>? ?? {};
    final pageNumber = (pageInfo['number'] as num?)?.toInt() ?? 0;
    final totalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
    return NotificationPage(items: items, hasMore: pageNumber + 1 < totalPages);
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
