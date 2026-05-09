import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/network/dio_client.dart';

class ArtistScheduleService {
  Future<List<ArtistScheduleModel>> fetchSchedule(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/schedule');
    return (response.data as List)
        .map((json) => ArtistScheduleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<FestivalPreview>> fetchFestivals(int artistId) async {
    final resp = await DioClient.dio.get('/artists/$artistId/schedule');
    final list = resp.data as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return FestivalPreview(
        id: (m['festivalId'] as num).toInt(),
        title: (m['title'] ?? '') as String,
        location: (m['location'] ?? '') as String,
        posterUrl: (m['posterUrl'] ?? '') as String,
        startDate: m['startDate']?.toString() ?? '',
      );
    }).toList();
  }
}
