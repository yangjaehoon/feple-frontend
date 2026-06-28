import 'package:feple/model/notification_page.dart';

abstract class NotificationFeedable {
  Future<NotificationPage> fetchPage(int page);
  Future<void> markRead(int id);
  Future<void> markAllRead();
}
