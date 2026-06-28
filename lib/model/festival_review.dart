class FestivalReview {
  final String nickname;
  final int rating;
  final String? userReview;
  final String? ratedAt;

  const FestivalReview({
    required this.nickname,
    required this.rating,
    this.userReview,
    this.ratedAt,
  });

  factory FestivalReview.fromJson(Map<String, dynamic> json) => FestivalReview(
        nickname: json['nickname'] as String,
        rating: json['rating'] as int,
        userReview: json['userReview'] as String?,
        ratedAt: json['ratedAt'] as String?,
      );
}
