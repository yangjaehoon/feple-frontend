import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/network/dio_client.dart';

class FestivalService {
  Future<List<FestivalPreview>> fetchPreviews({
    required int page,
    required int size,
    required bool includeEnded,
    List<String> genres = const [],
    List<String> regions = const [],
    List<String> ageRestrictions = const [],
  }) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
      'includeEnded': includeEnded,
    };
    if (genres.isNotEmpty) params['genres'] = genres;
    if (regions.isNotEmpty) params['regions'] = regions;
    if (ageRestrictions.isNotEmpty) params['ageRestrictions'] = ageRestrictions;

    final response = await DioClient.dio.get('/festivals', queryParameters: params);
    final decoded = response.data;
    final List<dynamic> list =
        decoded is List ? decoded : (decoded['content'] as List<dynamic>);

    return list
        .map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FestivalModel> fetchById(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId');
    return FestivalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FestivalModel>> fetchAll() async {
    final response = await DioClient.dio.get('/festivals');
    return (response.data as List)
        .map((json) => FestivalModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitFestival({
    required String title,
    required String description,
    required String location,
    required String startDate,
    required String endDate,
    required String posterUrl,
    required List<String> genres,
    required String region,
  }) =>
      DioClient.dio.post('/festivals', data: {
        'title': title,
        'description': description,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'posterUrl': posterUrl,
        'genres': genres,
        'region': region,
      });
}
