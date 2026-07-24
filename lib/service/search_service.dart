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
        .get('/search/suggestions', queryParameters: {'keyword': keyword});
    final list = response.data as List? ?? [];
    return list
        .map((item) => SearchSuggestion.fromJson(item as Map<String, dynamic>))
        .where((item) => item.label.isNotEmpty)
        .toList();
  }
}
