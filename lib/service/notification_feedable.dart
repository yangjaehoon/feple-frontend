import 'package:feple/model/notification_page.dart';

enum NotifFilter { all, cert, comment, festival }

extension NotifFilterApi on NotifFilter {
  String? get typeGroup => switch (this) {
    NotifFilter.all      => null,
    NotifFilter.cert     => 'cert',
    NotifFilter.comment  => 'comment',
    NotifFilter.festival => 'festival',
  };
}

abstract class NotificationFeedable {
  Future<NotificationPage> fetchPage(int page, {NotifFilter filter = NotifFilter.all});
  Future<void> markRead(int id);
  Future<void> markAllRead();
  Future<void> delete(int id);
  Future<void> deleteAll();
}
