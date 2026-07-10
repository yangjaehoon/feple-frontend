import 'package:feple/model/notification_page.dart';

enum NotificationFilter { all, cert, comment, festival }

extension NotificationFilterApi on NotificationFilter {
  String? get typeGroup => switch (this) {
    NotificationFilter.all      => null,
    NotificationFilter.cert     => 'cert',
    NotificationFilter.comment  => 'comment',
    NotificationFilter.festival => 'festival',
  };
}

abstract class NotificationFeedable {
  Future<NotificationPage> fetchPage(int page, {NotificationFilter filter = NotificationFilter.all});
  Future<void> markRead(int id);
  Future<void> markAllRead();
  Future<void> delete(int id);
  Future<void> deleteAll();
}
