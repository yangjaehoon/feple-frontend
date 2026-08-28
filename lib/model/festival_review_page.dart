import 'package:feple/model/festival_review.dart';

import 'json_reader.dart';

/// 페스티벌 리뷰 목록 + 별점 통계 (별점 시트 페이지네이션용)
class FestivalReviewPage {
  final double averageRating;
  final int ratingCount;
  final Map<int, int> distribution;
  final List<FestivalReview> reviews;
  final bool hasNext;

  const FestivalReviewPage({
    required this.averageRating,
    required this.ratingCount,
    required this.distribution,
    required this.reviews,
    required this.hasNext,
  });

  factory FestivalReviewPage.fromJson(Map<String, dynamic> json) {
    final rawDist = json.objectOrNull('distribution') ?? const <String, dynamic>{};
    return FestivalReviewPage(
      averageRating: json.dbl('averageRating'),
      ratingCount: json.integer('ratingCount'),
      distribution: rawDist.map(
        (k, v) => MapEntry(int.tryParse(k) ?? 0, v is num ? v.toInt() : 0),
      ),
      reviews: json.objectList('reviews').map(FestivalReview.fromJson).toList(),
      hasNext: json.boolean('hasNext'),
    );
  }
}
