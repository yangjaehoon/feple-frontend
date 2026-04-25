import 'package:feple/screen/notification/notification_type.dart';

class NotificationModel {
  final int id;
  final NotificationType? type;
  final String title;
  final String body;
  final int? referenceId;
  final bool read;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    required this.read,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num).toInt(),
      type: NotificationType.fromValue(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      referenceId: json['referenceId'] != null
          ? (json['referenceId'] as num).toInt()
          : null,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }

  NotificationModel copyWithRead() => NotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
        read: true,
        createdAt: createdAt,
      );
}
