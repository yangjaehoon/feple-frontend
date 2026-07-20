import 'package:feple/model/notification_type.dart';

import 'localized_text.dart';

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
  final String? imageUrl;

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
    this.imageUrl,
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
      imageUrl: json['imageUrl'] as String?,
    );
  }

  DateTime? get createdAtDate =>
      createdAt != null ? DateTime.tryParse(createdAt!) : null;

  String displayTitle(bool isEnglish) =>
      pickLocalized(isEnglish, title, titleEn);

  String displayBody(bool isEnglish) => pickLocalized(isEnglish, body, bodyEn);

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
    imageUrl: imageUrl,
  );
}
