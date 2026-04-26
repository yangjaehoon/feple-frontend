import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_poster.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_timetable.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artists.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_board.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_booth_map.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';

class FestivalInformationFragment extends StatefulWidget {
  const FestivalInformationFragment({super.key, required this.poster});

  final FestivalModel poster;

  @override
  State<FestivalInformationFragment> createState() =>
      _FestivalInformationFragmentState();
}

class _FestivalInformationFragmentState
    extends State<FestivalInformationFragment> {
  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rs = ResponsiveSize(context);
    return Container(
      color: colors.backgroundMain,
      child: Stack(
        children: [
          RefreshIndicator(
            color: colors.activate,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: rs.h(AppDimens.scrollPaddingBottom),
              ),
              child: Column(
                children: [
                  FestivalPoster(
                    key: ValueKey('poster_$_refreshKey'),
                    poster: widget.poster,
                  ),
                  const SizedBox(height: 16),
                  FestivalArtists(
                    key: ValueKey('artists_$_refreshKey'),
                    festivalId: widget.poster.id,
                  ),
                  FestivalBoard(
                    key: ValueKey('board_$_refreshKey'),
                    festivalId: widget.poster.id,
                    festivalName: widget.poster.title,
                  ),
                  FestivalTimetable(
                    key: ValueKey('timetable_$_refreshKey'),
                    festivalId: widget.poster.id,
                    startDate: widget.poster.startDate,
                    endDate: widget.poster.endDate,
                  ),
                  FestivalBoothMap(
                    key: ValueKey('map_$_refreshKey'),
                    festivalId: widget.poster.id,
                    festivalLat: widget.poster.latitude,
                    festivalLng: widget.poster.longitude,
                  ),
                ],
              ),
            ),
          ),
          FepleAppBar('festival_detail'.tr(), showBackButton: true),
        ],
      ),
    );
  }
}
