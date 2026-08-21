import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_offline_banner.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_section.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_poster.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_timetable.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artists.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_board.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_booth_map.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_setlist.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

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
  final _posterKey = GlobalKey<FestivalPosterState>();
  final _artistsKey = GlobalKey<FestivalArtistsState>();
  final _boardKey = GlobalKey<BoardPreviewSectionState>();
  final _timetableKey = GlobalKey<FestivalTimetableState>();
  final _setlistKey = GlobalKey<FestivalSetlistState>();
  final _mapKey = GlobalKey<FestivalBoothMapState>();

  // 홈/목록/검색 등에서 넘어온 widget.poster는 미리보기·캐시 데이터라
  // startDate/endDate/latitude/longitude 등이 오래됐을 수 있다 — 아티스트/게시판
  // 섹션과 달리 타임테이블·부스맵은 이 값을 생성 시점에만 쓰므로, 최초 페인트는
  // widget.poster로 즉시 보여주고 곧바로 상세 재조회 결과로 갈아끼운다.
  // (FestivalPoster 자신은 별도로 자체 재조회하므로 여기서 건드리지 않는다.)
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
    // 각 섹션의 refresh()가 실제로 끝날 때까지 기다려야 당겨서 새로고침 스피너가
    // 화면 갱신 완료와 맞물려 사라짐 (artist_page의 동일 패턴 참고)
    await Future.wait([
      _refreshPoster(),
      _posterKey.currentState?.refresh() ?? Future.value(),
      _artistsKey.currentState?.refresh() ?? Future.value(),
      _boardKey.currentState?.refresh() ?? Future.value(),
      _timetableKey.currentState?.refresh() ?? Future.value(),
      _setlistKey.currentState?.refresh() ?? Future.value(),
      _mapKey.currentState?.refresh() ?? Future.value(),
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
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
        child: Column(
          children: [
            FestivalPoster(
              key: _posterKey,
              poster: widget.poster,
              heroTag: widget.heroTag,
            ),
            const SizedBox(height: 16),
            FestivalArtists(
              key: _artistsKey,
              festivalId: _poster.id,
            ),
            FestivalBoard(
              boardKey: _boardKey,
              festivalId: _poster.id,
              festivalName: _poster.displayTitle(context.isEnglish),
            ),
            FestivalTimetable(
              key: _timetableKey,
              festivalId: _poster.id,
              startDate: _poster.startDate,
              endDate: _poster.endDate,
            ),
            FestivalBoothMap(
              key: _mapKey,
              festivalId: _poster.id,
              festivalLat: _poster.latitude,
              festivalLng: _poster.longitude,
            ),
            FestivalSetlist(
              key: _setlistKey,
              festivalId: _poster.id,
            ),
          ],
        ),
      ),
    );
  }
}
