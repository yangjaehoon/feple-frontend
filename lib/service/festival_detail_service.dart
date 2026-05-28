import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/network/dio_client.dart';

class FestivalDetailService {
  Future<List<FestivalArtistItem>> fetchFestivalArtists(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/artists');
    return (response.data as List)
        .map((e) => FestivalArtistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BoothModel>> fetchBooths(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/booths');
    return (response.data as List)
        .map((json) => BoothModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimetableEntry>> fetchTimetable(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/timetable');
    final raw = response.data;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((e) => TimetableEntry.fromJson(e))
        .toList();
  }

  Future<WeatherModel?> fetchWeather(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/weather');
    if (response.statusCode == 204 || response.data == null) return null;
    return WeatherModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FestivalSetlistEntry>> fetchSetlist(int festivalId) async {
    final response = await DioClient.dio.get('/festivals/$festivalId/setlist');
    return (response.data as List)
        .map((e) => FestivalSetlistEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateSetlist(int festivalId, int artistFestivalId, List<int> songIds) =>
      DioClient.dio.put(
        '/festivals/$festivalId/artists/$artistFestivalId/setlist',
        data: songIds,
      );
}
