import 'package:feple/model/notification_filter.dart';
import 'package:feple/model/notification_page.dart';

export 'package:feple/model/notification_filter.dart';

abstract class NotificationFeedable {
  Future<NotificationPage> fetchPage(int page, {NotificationFilter filter = NotificationFilter.all});
  Future<void> markRead(int id);
  Future<void> markAllRead();
  Future<void> delete(int id);
  Future<void> deleteAll();
}
