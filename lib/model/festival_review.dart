import 'json_reader.dart';

class FestivalReview {
  final int reviewId;
  final String nickname;
  final int rating;
  final String? userReview;
  final String? ratedAt;
  final int likeCount;
  final bool likedByMe;

  const FestivalReview({
    required this.reviewId,
    required this.nickname,
    required this.rating,
    this.userReview,
    this.ratedAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  factory FestivalReview.fromJson(Map<String, dynamic> json) => FestivalReview(
        reviewId: json.integer('reviewId'),
        nickname: json.str('nickname'),
        rating: json.integer('rating'),
        userReview: json.strOrNull('userReview'),
        ratedAt: json.strOrNull('ratedAt'),
        likeCount: json.integer('likeCount'),
        likedByMe: json.boolean('likedByMe'),
      );
}
