import 'package:feple/model/notification_type.dart';

import 'json_reader.dart';
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
      id: json.integer('id'),
      type: NotificationType.fromValue(json.strOrNull('type')),
      title: json.str('title'),
      body: json.str('body'),
      titleEn: json.str('titleEn'),
      bodyEn: json.str('bodyEn'),
      referenceId: json.intOrNull('referenceId'),
      read: json.boolean('read'),
      createdAt: json.strOrNull('createdAt'),
      imageUrl: json.strOrNull('imageUrl'),
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
