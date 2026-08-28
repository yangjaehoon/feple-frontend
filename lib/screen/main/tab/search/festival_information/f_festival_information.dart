import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/widget/w_offline_banner.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_poster.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_timetable.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artists.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_board.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_booth_map.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_setlist.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/forced_refresh.dart';

class FestivalInformationFragment extends StatefulWidget {
  const FestivalInformationFragment({super.key, required this.poster, this.heroTag});

  final FestivalModel poster;
  final String? heroTag;

  @override
  State<FestivalInformationFragment> createState() =>
      _FestivalInformationFragmentState();
}

class _FestivalInformationFragmentState
    extends State<FestivalInformationFragment> {
  final _refresh = RefreshCoordinator();

  // 홈/목록/검색 등에서 넘어온 widget.poster는 미리보기·캐시 데이터라
  // startDate/endDate/latitude/longitude 등이 오래됐을 수 있다 — 최초 페인트는
  // widget.poster로 즉시 보여주고 곧바로 상세 재조회 결과로 갈아끼워 모든 하위
  // 섹션(FestivalPoster 포함)에 전달한다. 재조회는 여기 한 곳에서만 한다 —
  // FestivalPoster가 스스로 또 재조회하면 같은 API를 화면 진입마다 두 번
  // 호출하게 된다.
  late FestivalModel _poster;

  @override
  void initState() {
    super.initState();
    _poster = widget.poster;
    unawaited(_refreshPoster());
  }

  Future<void> _refreshPoster() async {
    try {
      final fresh = await sl<FestivalService>().fetchById(widget.poster.id);
      if (mounted) setState(() => _poster = fresh);
    } catch (e) {
      debugPrint('[FestivalInformationFragment] 최신 페스티벌 정보 갱신 실패: $e');
    }
  }

  Future<void> _onRefresh() async {
    // 포스터 재조회 + 모든 섹션이 실제로 끝날 때까지 기다려야 당겨서 새로고침
    // 스피너가 화면 갱신 완료와 맞물려 사라진다.
    await Future.wait([
      _refreshPoster(),
      _refresh.refreshAll(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return OfflineBanner(
      child: Container(
        color: colors.backgroundMain,
        child: Stack(
          children: [
            _buildScrollBody(colors),
            FepleAppBar('festival_detail'.tr(), showBackButton: true),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollBody(AbstractThemeColors colors) {
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: () => withForcedRefresh(_onRefresh),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
        child: RefreshScope(
          coordinator: _refresh,
          child: Column(
            children: [
              FestivalPoster(
                poster: _poster,
                heroTag: widget.heroTag,
              ),
              const SizedBox(height: AppDimens.space16),
              FestivalArtists(
                festivalId: _poster.id,
              ),
              FestivalBoard(
                festivalId: _poster.id,
                festivalName: _poster.displayTitle(context.isEnglish),
              ),
              FestivalTimetable(
                festivalId: _poster.id,
                startDate: _poster.startDate,
                endDate: _poster.endDate,
              ),
              FestivalBoothMap(
                festivalId: _poster.id,
                festivalLat: _poster.latitude,
                festivalLng: _poster.longitude,
              ),
              FestivalSetlist(
                festivalId: _poster.id,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
