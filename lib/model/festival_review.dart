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
        reviewId: (json['reviewId'] as num).toInt(),
        nickname: json['nickname'] as String,
        rating: (json['rating'] as num).toInt(),
        userReview: json['userReview'] as String?,
        ratedAt: json['ratedAt'] as String?,
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
        likedByMe: (json['likedByMe'] as bool?) ?? false,
      );
}
