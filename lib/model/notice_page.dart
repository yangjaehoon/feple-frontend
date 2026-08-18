import 'package:feple/model/notice_model.dart';

/// 공지사항 목록 (Spring Page 응답 매핑용)
class NoticePage {
  final List<NoticeModel> notices;
  final bool hasNext;

  const NoticePage({required this.notices, required this.hasNext});

  factory NoticePage.fromJson(Map<String, dynamic> json) {
    return NoticePage(
      notices: (json['content'] as List)
          .cast<Map<String, dynamic>>()
          .map(NoticeModel.fromJson)
          .toList(),
      hasNext: !(json['last'] as bool? ?? true),
    );
  }
}
