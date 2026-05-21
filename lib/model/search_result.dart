class SearchResult {
  final List<dynamic> artists;
  final List<dynamic> festivals;
  final List<dynamic> posts;

  const SearchResult({
    required this.artists,
    required this.festivals,
    required this.posts,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        artists: json['artists'] as List? ?? [],
        festivals: json['festivals'] as List? ?? [],
        posts: json['posts'] as List? ?? [],
      );
}
