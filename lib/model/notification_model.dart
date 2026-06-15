import 'package:feple/model/notification_type.dart';

class NotificationModel {
  final int id;
  final NotificationType? type;
  final String title;
  final String body;
  final String titleEn;
  final String bodyEn;
  final int? referenceId;
  final bool read;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.titleEn = '',
    this.bodyEn = '',
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
      titleEn: json['titleEn'] as String? ?? '',
      bodyEn: json['bodyEn'] as String? ?? '',
      referenceId: json['referenceId'] != null
          ? (json['referenceId'] as num).toInt()
          : null,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }

  String? get formattedDate {
    if (createdAt == null) return null;
    return createdAt!.length >= 10 ? createdAt!.substring(0, 10) : createdAt;
  }

  String displayTitle(bool isEnglish) =>
      isEnglish && titleEn.isNotEmpty ? titleEn : title;

  String displayBody(bool isEnglish) =>
      isEnglish && bodyEn.isNotEmpty ? bodyEn : body;

  NotificationModel copyWithRead() => NotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        titleEn: titleEn,
        bodyEn: bodyEn,
        referenceId: referenceId,
        read: true,
        createdAt: createdAt,
      );
}
