import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/w_festival_poster.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/w_festival_timetable.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/w_festival_artists.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/w_festival_board.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/w_festival_booth_map.dart';
import 'package:fast_app_base/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';

class FestivalInformationFragment extends StatelessWidget {
  const FestivalInformationFragment({super.key, required this.poster});

  final PosterModel poster;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rs = ResponsiveSize(context);
    return Container(
      color: colors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: rs.h(AppDimens.scrollPaddingBottom),
            ),
            child: Column(
              children: [
                FestivalPoster(poster: poster),
                FestivalArtists(festivalId: poster.id),
                FestivalBoard(
                    festivalId: poster.id, festivalName: poster.title),
                FestivalTimetable(
                  festivalId: poster.id,
                  startDate: poster.startDate,
                  endDate: poster.endDate,
                ),
                FestivalBoothMap(
                  festivalId: poster.id,
                  festivalLat: poster.latitude,
                  festivalLng: poster.longitude,
                ),
              ],
            ),
          ),
          FepleAppBar('festival_detail'.tr()),
        ],
      ),
    );
  }
}
