import 'package:feple/model/festival_review.dart';

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
    final rawDist = json['distribution'] as Map<String, dynamic>;
    return FestivalReviewPage(
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingCount: (json['ratingCount'] as num).toInt(),
      distribution: rawDist.map((k, v) => MapEntry(int.parse(k), (v as num).toInt())),
      reviews: (json['reviews'] as List)
          .cast<Map<String, dynamic>>()
          .map(FestivalReview.fromJson)
          .toList(),
      hasNext: json['hasNext'] as bool,
    );
  }
}
