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

  DateTime? get createdAtDate => createdAt != null ? DateTime.tryParse(createdAt!) : null;

  String relativeTime(bool isKorean) {
    final date = createdAtDate;
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (isKorean) {
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}개월 전';
      return '${(diff.inDays / 365).floor()}년 전';
    } else {
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
      return '${(diff.inDays / 365).floor()}y ago';
    }
  }

  String sectionLabel(bool isKorean) {
    final date = createdAtDate;
    if (date == null) return isKorean ? '이전' : 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(itemDay).inDays;
    if (diff == 0) return isKorean ? '오늘' : 'Today';
    if (diff == 1) return isKorean ? '어제' : 'Yesterday';
    if (diff < 7) return isKorean ? '이번 주' : 'This week';
    return isKorean ? '이전' : 'Earlier';
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
        imageUrl: imageUrl,
      );
}
