import 'package:feple/model/notification_model.dart';

class NotificationPage {
  final List<NotificationModel> items;
  final bool hasMore;

  const NotificationPage({required this.items, required this.hasMore});
}
