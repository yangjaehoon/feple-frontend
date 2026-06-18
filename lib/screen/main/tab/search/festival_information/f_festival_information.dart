import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_named_board.dart';
import 'package:feple/common/widget/w_offline_banner.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_poster.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_timetable.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artists.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_board.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_booth_map.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_setlist.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
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
  final _boardKey = GlobalKey<NamedBoardState>();
  final _timetableKey = GlobalKey<FestivalTimetableState>();
  final _setlistKey = GlobalKey<FestivalSetlistState>();
  final _mapKey = GlobalKey<FestivalBoothMapState>();

  Future<void> _onRefresh() async {
    _posterKey.currentState?.refresh();
    _artistsKey.currentState?.refresh();
    _boardKey.currentState?.refresh();
    _timetableKey.currentState?.refresh();
    _setlistKey.currentState?.refresh();
    _mapKey.currentState?.refresh();
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
              festivalId: widget.poster.id,
            ),
            FestivalBoard(
              boardKey: _boardKey,
              festivalId: widget.poster.id,
              festivalName: widget.poster.title,
            ),
            FestivalTimetable(
              key: _timetableKey,
              festivalId: widget.poster.id,
              startDate: widget.poster.startDate,
              endDate: widget.poster.endDate,
            ),
            FestivalBoothMap(
              key: _mapKey,
              festivalId: widget.poster.id,
              festivalLat: widget.poster.latitude,
              festivalLng: widget.poster.longitude,
            ),
            FestivalSetlist(
              key: _setlistKey,
              festivalId: widget.poster.id,
            ),
          ],
        ),
      ),
    );
  }
}
