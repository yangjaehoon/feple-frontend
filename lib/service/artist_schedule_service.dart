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
      final scheduleJson = e as Map<String, dynamic>;
      return FestivalPreview(
        id: (scheduleJson['festivalId'] as num).toInt(),
        title: (scheduleJson['title'] ?? '') as String,
        location: (scheduleJson['location'] ?? '') as String,
        posterUrl: (scheduleJson['posterUrl'] ?? '') as String,
        startDate: scheduleJson['startDate']?.toString() ?? '',
      );
    }).toList();
  }
}
