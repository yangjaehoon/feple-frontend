import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/w_festival_poster.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/w_festival_timetable.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/w_festival_board.dart';
import 'package:fast_app_base/screen/main/tab/home/w_feple_app_bar.dart';
import 'package:flutter/material.dart';

class FestivalInformationFragment extends StatelessWidget {
  
  const FestivalInformationFragment({
    Key? key, required this.poster
  }) : super(key: key);

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
              top: rs.h(AppDimens.scrollPaddingTop),
              bottom: rs.h(AppDimens.scrollPaddingBottom),
            ),
            child: Column(
              children: [
                FestivalPoster(poster: poster),
                FestivalBoard(festivalId: poster.id, festivalName: poster.title),
                const FestivalTimetable(),
              ],
            ),
          ),
          const FepleAppBar("페스티벌 상세 페이지"),
        ],
      ),
    );
  }
}