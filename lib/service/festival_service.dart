import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/network/dio_client.dart';

class FestivalService {
  Future<List<FestivalPreview>> fetchPreviews({
    required int page,
    required int size,
    required bool includeEnded,
    List<String> genres = const [],
    List<String> regions = const [],
  }) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
      'includeEnded': includeEnded,
    };
    if (genres.isNotEmpty) params['genres'] = genres;
    if (regions.isNotEmpty) params['regions'] = regions;

    final resp = await DioClient.dio.get('/festivals', queryParameters: params);
    final decoded = resp.data;
    final List<dynamic> list =
        decoded is List ? decoded : (decoded['content'] as List<dynamic>);

    return list
        .map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FestivalModel> fetchById(int festivalId) async {
    final resp = await DioClient.dio.get('/festivals/$festivalId');
    return FestivalModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<FestivalArtistItem>> fetchFestivalArtists(int festivalId) async {
    final resp = await DioClient.dio.get('/festivals/$festivalId/artists');
    return (resp.data as List)
        .map((e) => FestivalArtistItem.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<bool> isLiked(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/liked');
    return response.data as bool;
  }

  Future<bool> toggleLike(int festivalId) async {
    final response = await DioClient.dio.post('/festivals/$festivalId/like');
    return response.data as bool;
  }

  Future<List<BoothModel>> fetchBooths(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/booths');
    return (response.data as List)
        .map((json) => BoothModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimetableEntry>> fetchTimetable(int festivalId) async {
    final resp = await DioClient.dio.get('/festivals/$festivalId/timetable');
    final raw = resp.data;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((e) => TimetableEntry.fromJson(e))
        .toList();
  }
}
