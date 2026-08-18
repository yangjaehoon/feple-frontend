import 'date_format.dart';

class NoticeModel {
  final int id;
  final String title;
  final String content;
  final bool pinned;
  final String? createdAt;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
    this.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) => NoticeModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        pinned: json['pinned'] as bool? ?? false,
        createdAt: json['createdAt'] as String?,
      );

  String? get formattedDate => formatShortDate(createdAt);
}
