/// 페스티벌 평균 별점 및 평가 수
class FestivalRatingSummary {
  final double averageRating;
  final int ratingCount;

  const FestivalRatingSummary({required this.averageRating, required this.ratingCount});

  factory FestivalRatingSummary.fromJson(Map<String, dynamic> json) =>
      FestivalRatingSummary(
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      );
}
