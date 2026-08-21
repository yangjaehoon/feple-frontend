import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/ticket_link.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/cache_fallback_fetcher.dart';
import 'package:feple/service/festival_artists_fetcher.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/festival_timetable_fetcher.dart';

class FestivalDetailService
    implements FestivalTimetableFetcher, FestivalArtistsFetcher {
  final FestivalCacheService _cache;

  FestivalDetailService(this._cache);

  @override
  Future<List<FestivalArtistItem>> fetchFestivalArtists(int festivalId) =>
      fetchWithCacheFallback(
        request: () => DioClient.dio.get('/festivals/$festivalId/artists'),
        parse: (data) => (data as List)
            .map((e) => FestivalArtistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        save: (items) => _cache.saveArtists(festivalId, items),
        load: () => _cache.loadArtists(festivalId),
      );

  Future<List<BoothModel>> fetchBooths(int festivalId) => fetchWithCacheFallback(
        request: () => DioClient.dio.get('/festivals/$festivalId/booths'),
        // 좌표 없는 부스 하나가 섞여 있어도 전체 목록 조회가 실패하지 않도록,
        // 지도에 표시할 수 없는 항목은 조용히 걸러내고 나머지는 정상 표시한다.
        parse: (data) => (data is List ? data : <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .where((j) => j['latitude'] is num && j['longitude'] is num)
            .map(BoothModel.fromJson)
            .toList(),
        save: (items) => _cache.saveBooths(festivalId, items),
        load: () => _cache.loadBooths(festivalId),
      );

  @override
  Future<List<TimetableEntry>> fetchTimetable(int festivalId) =>
      fetchWithCacheFallback(
        request: () => DioClient.dio.get('/festivals/$festivalId/timetable'),
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
      fetchWithCacheFallback(
        request: () => DioClient.dio.get('/festivals/$festivalId/setlist'),
        parse: (data) => (data as List)
            .map((e) => FestivalSetlistEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        save: (items) => _cache.saveSetlist(festivalId, items),
        load: () => _cache.loadSetlist(festivalId),
      );

  // 관리자가 등록/삭제하는 데이터라 리스트/검색 등 미리보기용 festival 응답에는
  // 포함돼 있지 않음 — 상세 화면 진입 경로와 무관하게 항상 최신 값을 보이도록
  // 별도 엔드포인트로 조회한다(예매 링크가 있을 때만 티켓 버튼을 노출하는 데 사용).
  Future<List<TicketLink>> fetchTicketLinks(int festivalId) async {
    final response =
        await DioClient.dio.get('/festivals/$festivalId/ticket-links');
    return (response.data as List)
        .map((e) => TicketLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitSetlistRequest({
    required int festivalId,
    required int artistFestivalId,
    required String message,
  }) =>
      DioClient.dio.post(
        '/festivals/$festivalId/setlist-requests',
        data: {
          'artistFestivalId': artistFestivalId,
          'message': message,
        },
      );
}
