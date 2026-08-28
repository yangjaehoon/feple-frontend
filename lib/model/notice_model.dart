import 'date_format.dart';
import 'json_reader.dart';

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
        id: json.integer('id'),
        title: json.str('title'),
        content: json.str('content'),
        pinned: json.boolean('pinned'),
        createdAt: json.strOrNull('createdAt'),
      );

  String? get formattedDate => formatShortDate(createdAt);
}
