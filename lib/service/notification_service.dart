import 'package:feple/common/util/response_parsing.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/model/notification_page.dart';
import 'package:feple/model/spring_page.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/service/notification_feedable.dart';

export 'package:feple/model/notification_page.dart';

class NotificationService implements NotificationCountable, NotificationFeedable {
  static const int _pageSize = 20;

  @override
  Future<NotificationPage> fetchPage(int page, {NotificationFilter filter = NotificationFilter.all}) async {
    final params = <String, dynamic>{'page': page, 'size': _pageSize};
    final group = filter.typeGroup;
    if (group != null) params['typeGroup'] = group;

    final response = await DioClient.dio.get('/notifications', queryParameters: params);
    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final items = extractJsonList(response.data)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasMore = springPageHasMore(data['page'] as Map<String, dynamic>?);
    return NotificationPage(items: items, hasMore: hasMore);
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await DioClient.dio.get('/notifications/unread-count');
    // 서버가 {"count": N} 또는 순수 숫자 어느 쪽을 주든, 예상 밖 형태면 0.
    final data = response.data;
    if (data is num) return data.toInt();
    if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
    return 0;
  }

  @override
  Future<void> markRead(int id) async {
    await DioClient.dio.patch('/notifications/$id/read');
  }

  @override
  Future<void> markAllRead() async {
    await DioClient.dio.patch('/notifications/read-all');
  }

  @override
  Future<void> delete(int id) async {
    await DioClient.dio.delete('/notifications/$id');
  }

  @override
  Future<void> deleteAll() async {
    await DioClient.dio.delete('/notifications');
  }
}
