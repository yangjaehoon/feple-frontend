import 'package:feple/model/festival_model.dart';
import 'package:flutter/foundation.dart';
import 'festival_detail_service.dart';

/// 홈 로드 직후 백그라운드에서 주요 엔드포인트를 미리 캐싱.
/// 페스티벌 현장 저신호 환경에서 처음 진입하는 화면도 즉시 표시하기 위함.
class CachePrefetchService {
  final FestivalDetailService _detail;

  CachePrefetchService(this._detail);

  /// 종료되지 않은 페스티벌에 대해 순차적으로 프리페치.
  /// 느린 네트워크 부하를 줄이기 위해 축제당 4개 엔드포인트를 동시 요청하되
  /// 축제 간에는 순차 처리.
  Future<void> prefetchForFestivals(List<FestivalModel> festivals) async {
    final targets = festivals.where((f) => !f.isEnded).toList();
    for (final festival in targets) {
      await _prefetchOne(festival.id);
    }
  }

  Future<void> _prefetchOne(int festivalId) async {
    await Future.wait([
      _safe(() => _detail.fetchTimetable(festivalId)),
      _safe(() => _detail.fetchSetlist(festivalId)),
      _safe(() => _detail.fetchWeather(festivalId)),
      _safe(() => _detail.fetchFestivalArtists(festivalId)),
    ]);
  }

  Future<void> _safe(Future<dynamic> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('[Prefetch] 캐시 프리페치 실패 (무시): $e');
    }
  }
}
