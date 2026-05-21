import 'package:feple/model/search_result.dart';
import 'package:feple/model/search_suggestion.dart';
import 'package:feple/network/dio_client.dart';

export 'package:feple/model/search_result.dart';
export 'package:feple/model/search_suggestion.dart';

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
