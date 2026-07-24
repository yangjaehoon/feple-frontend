class PostInteractionData {
  final bool liked;
  final int likeCount;
  final int commentCount;
  final bool scraped;
  final int scrapCount;

  const PostInteractionData({
    required this.liked,
    required this.likeCount,
    required this.commentCount,
    required this.scraped,
    required this.scrapCount,
  });
}
