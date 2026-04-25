import 'package:feple/model/festival_artist_item.dart';
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
}
