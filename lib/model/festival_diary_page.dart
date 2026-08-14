import 'package:feple/model/festival_diary_model.dart';

/// 페스티벌 상세의 공개 일기 피드 (Spring Page 응답 매핑용)
class FestivalDiaryPage {
  final List<FestivalDiaryModel> diaries;
  final bool hasNext;

  const FestivalDiaryPage({required this.diaries, required this.hasNext});

  factory FestivalDiaryPage.fromJson(Map<String, dynamic> json) {
    return FestivalDiaryPage(
      diaries: (json['content'] as List)
          .cast<Map<String, dynamic>>()
          .map(FestivalDiaryModel.fromJson)
          .toList(),
      hasNext: !(json['last'] as bool? ?? true),
    );
  }
}
