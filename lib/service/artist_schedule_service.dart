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

  Future<List<FestivalPreview>> fetchFestivals(int artistId) async {
    final schedules = await fetchSchedule(artistId);
    return schedules
        .map((s) => FestivalPreview(
              id: s.festivalId,
              title: s.title,
              location: s.location ?? '',
              posterUrl: s.posterUrl ?? '',
              startDate: s.startDate ?? '',
              endDate: s.endDate,
            ))
        .toList();
  }
}
