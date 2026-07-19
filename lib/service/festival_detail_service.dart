import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_artists_fetcher.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/festival_timetable_fetcher.dart';

class FestivalDetailService
    implements FestivalTimetableFetcher, FestivalArtistsFetcher {
  final FestivalCacheService _cache;

  FestivalDetailService(this._cache);

  /// GET 요청 → 캐시 저장, 오프라인이면서 캐시가 있으면 캐시로 폴백.
  Future<List<T>> _fetchWithCacheFallback<T>({
    required String endpoint,
    required List<T> Function(dynamic data) parse,
    required Future<void> Function(List<T> items) save,
    required Future<List<T>?> Function() load,
  }) async {
    try {
      final response = await DioClient.dio.get(endpoint);
      final items = parse(response.data);
      await save(items);
      return items;
    } catch (e) {
      if (isOffline(e)) {
        final cached = await load();
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<FestivalArtistItem>> fetchFestivalArtists(int festivalId) =>
      _fetchWithCacheFallback(
        endpoint: '/festivals/$festivalId/artists',
        parse: (data) => (data as List)
            .map((e) => FestivalArtistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        save: (items) => _cache.saveArtists(festivalId, items),
        load: () => _cache.loadArtists(festivalId),
      );

  Future<List<BoothModel>> fetchBooths(int festivalId) => _fetchWithCacheFallback(
        endpoint: '/festivals/$festivalId/booths',
        parse: (data) => (data as List)
            .map((json) => BoothModel.fromJson(json as Map<String, dynamic>))
            .toList(),
        save: (items) => _cache.saveBooths(festivalId, items),
        load: () => _cache.loadBooths(festivalId),
      );

  @override
  Future<List<TimetableEntry>> fetchTimetable(int festivalId) =>
      _fetchWithCacheFallback(
        endpoint: '/festivals/$festivalId/timetable',
        parse: (data) => (data is List ? data : <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map((e) => TimetableEntry.fromJson(e))
            .toList(),
        save: (items) => _cache.saveTimetable(festivalId, items),
        load: () => _cache.loadTimetable(festivalId),
      );

  // 날씨는 실시간 데이터라 캐시하지 않음
  Future<WeatherModel?> fetchWeather(int festivalId) async {
    final response =
        await DioClient.dio.get('/festivals/$festivalId/weather');
    if (response.statusCode == 204 || response.data == null) return null;
    return WeatherModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FestivalSetlistEntry>> fetchSetlist(int festivalId) =>
      _fetchWithCacheFallback(
        endpoint: '/festivals/$festivalId/setlist',
        parse: (data) => (data as List)
            .map((e) => FestivalSetlistEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        save: (items) => _cache.saveSetlist(festivalId, items),
        load: () => _cache.loadSetlist(festivalId),
      );

  Future<void> submitSetlistRequest({
    required int festivalId,
    required int artistFestivalId,
    required String artistName,
    required String message,
  }) =>
      DioClient.dio.post(
        '/festivals/$festivalId/setlist-requests',
        data: {
          'artistFestivalId': artistFestivalId,
          'artistName': artistName,
          'message': message,
        },
      );
}
