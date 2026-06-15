import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_cache_service.dart';

class FestivalDetailService {
  final FestivalCacheService _cache;

  FestivalDetailService(this._cache);

  Future<List<FestivalArtistItem>> fetchFestivalArtists(int festivalId) async {
    try {
      final response =
          await DioClient.dio.get('/festivals/$festivalId/artists');
      final items = (response.data as List)
          .map((e) => FestivalArtistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      await _cache.saveArtists(festivalId, items);
      return items;
    } catch (e) {
      if (isOffline(e)) {
        final cached = await _cache.loadArtists(festivalId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  Future<List<BoothModel>> fetchBooths(int festivalId) async {
    try {
      final response = await DioClient.dio.get('/festivals/$festivalId/booths');
      final items = (response.data as List)
          .map((json) => BoothModel.fromJson(json as Map<String, dynamic>))
          .toList();
      await _cache.saveBooths(festivalId, items);
      return items;
    } catch (e) {
      if (isOffline(e)) {
        final cached = await _cache.loadBooths(festivalId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  Future<List<TimetableEntry>> fetchTimetable(int festivalId) async {
    try {
      final response =
          await DioClient.dio.get('/festivals/$festivalId/timetable');
      final raw = response.data;
      final items = (raw is List ? raw : <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map((e) => TimetableEntry.fromJson(e))
          .toList();
      await _cache.saveTimetable(festivalId, items);
      return items;
    } catch (e) {
      if (isOffline(e)) {
        final cached = await _cache.loadTimetable(festivalId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  // 날씨는 실시간 데이터라 캐시하지 않음
  Future<WeatherModel?> fetchWeather(int festivalId) async {
    final response =
        await DioClient.dio.get('/festivals/$festivalId/weather');
    if (response.statusCode == 204 || response.data == null) return null;
    return WeatherModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FestivalSetlistEntry>> fetchSetlist(int festivalId) async {
    try {
      final response =
          await DioClient.dio.get('/festivals/$festivalId/setlist');
      final items = (response.data as List)
          .map((e) =>
              FestivalSetlistEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      await _cache.saveSetlist(festivalId, items);
      return items;
    } catch (e) {
      if (isOffline(e)) {
        final cached = await _cache.loadSetlist(festivalId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  Future<void> updateSetlist(
          int festivalId, int artistFestivalId, List<int> songIds) =>
      DioClient.dio.put(
        '/festivals/$festivalId/artists/$artistFestivalId/setlist',
        data: songIds,
      );
}
