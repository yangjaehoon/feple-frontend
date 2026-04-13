import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/screen/main/tab/search/w_circle_artist.dart';
import 'package:feple/screen/main/tab/search/w_concert_list_swiper.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';

class SearchFragment extends StatelessWidget {
  const SearchFragment({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    return Container(
      color: context.appColors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: rs.h(AppDimens.scrollPaddingTop),
              bottom: rs.h(AppDimens.scrollPaddingBottom),
            ),
            child: const Column(
              children: [
                ConcertListSwiperWidget(),
                CircleArtistWidget(),
              ],
            ),
          ),
          FepleAppBar("Feple"),
        ],
      ),
    );
  }
}
