import 'package:feple/network/dio_client.dart';

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

class SearchSuggestion {
  final String label;
  final String type; // 'artist' or 'festival'
  const SearchSuggestion(this.label, this.type);
}

class SearchService {
  Future<SearchResult> search(String keyword) async {
    final response = await DioClient.dio
        .get('/search', queryParameters: {'keyword': keyword.trim()});
    return SearchResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SearchSuggestion>> suggestions(String keyword) async {
    final response = await DioClient.dio
        .get('/search', queryParameters: {'keyword': keyword});
    final data = response.data as Map<String, dynamic>;
    final artists = (data['artists'] as List? ?? [])
        .map((artist) =>
            SearchSuggestion(artist['name'] as String? ?? '', 'artist'))
        .where((item) => item.label.isNotEmpty);
    final festivals = (data['festivals'] as List? ?? [])
        .map((festival) =>
            SearchSuggestion(festival['title'] as String? ?? '', 'festival'))
        .where((item) => item.label.isNotEmpty);
    return [...artists, ...festivals];
  }
}
