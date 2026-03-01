import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/screen/main/tab/home/w_circle_artist.dart';
import 'package:fast_app_base/screen/main/tab/home/w_concert_list_swiper.dart';
import 'package:fast_app_base/screen/main/tab/home/w_feple_app_bar.dart';
import 'package:flutter/material.dart';

class HomeFragment extends StatelessWidget {
  const HomeFragment({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.backgroundMain,
      child: Stack(
        children: [
          const SingleChildScrollView(
            padding: EdgeInsets.only(
              top: AppDimens.scrollPaddingTop,
              bottom: AppDimens.scrollPaddingBottom,
            ),
            child: Column(
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
