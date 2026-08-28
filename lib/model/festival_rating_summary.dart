import 'json_reader.dart';

/// 페스티벌 평균 별점 및 평가 수
class FestivalRatingSummary {
  final double averageRating;
  final int ratingCount;

  const FestivalRatingSummary({required this.averageRating, required this.ratingCount});

  factory FestivalRatingSummary.fromJson(Map<String, dynamic> json) =>
      FestivalRatingSummary(
        averageRating: json.dbl('averageRating'),
        ratingCount: json.integer('ratingCount'),
      );
}
