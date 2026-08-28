import 'package:feple/common/util/silent_failure.dart';
import 'package:feple/model/festival_model.dart';
import 'festival_detail_service.dart';

/// 홈 로드 직후 백그라운드에서 주요 엔드포인트를 미리 캐싱.
/// 페스티벌 현장 저신호 환경에서 처음 진입하는 화면도 즉시 표시하기 위함.
class CachePrefetchService {
  // 좋아요한 페스티벌이 수십 개인 유저에서 홈 로드마다 (축제 수 × 4) 요청이
  // 백그라운드로 쏟아지는 것을 막는다. 곧 다가오는 축제일수록 다음에 열어볼
  // 확률이 높으므로 시작일 오름차순으로 앞에서 N개만 프리페치한다.
  static const _maxFestivals = 5;

  final FestivalDetailService _detail;

  CachePrefetchService(this._detail);

  /// 종료되지 않은 축제 중 시작일이 가까운 순으로 최대 [_maxFestivals]개를
  /// 순차 프리페치. 느린 네트워크 부하를 줄이기 위해 축제당 4개 엔드포인트는
  /// 동시 요청하되 축제 간에는 순차 처리.
  Future<void> prefetchForFestivals(List<FestivalModel> festivals) async {
    final targets = festivals.where((f) => !f.isEnded).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (final festival in targets.take(_maxFestivals)) {
      await _prefetchOne(festival.id);
    }
  }

  Future<void> _prefetchOne(int festivalId) async {
    const tag = '[Prefetch] 캐시 프리페치 실패 (무시)';
    await Future.wait([
      runIgnoringErrors(tag, () => _detail.fetchTimetable(festivalId)),
      runIgnoringErrors(tag, () => _detail.fetchSetlist(festivalId)),
      runIgnoringErrors(tag, () => _detail.fetchWeather(festivalId)),
      runIgnoringErrors(tag, () => _detail.fetchFestivalArtists(festivalId)),
    ]);
  }
}
