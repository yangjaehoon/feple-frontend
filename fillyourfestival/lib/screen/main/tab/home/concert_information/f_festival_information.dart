import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/w_festival_poster.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/w_festival_timetable.dart';
import 'package:fast_app_base/screen/main/tab/home/w_feple_app_bar.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';
import 'package:flutter/material.dart';

class FestivalInformationFragment extends StatelessWidget {
  
  const FestivalInformationFragment({
    Key? key, required this.poster
  }) : super(key: key);

  final PosterModel poster;
  
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      color: colors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: AppDimens.scrollPaddingTop,
              bottom: AppDimens.scrollPaddingBottom,
            ),
            child: Column(
              children: [
                FestivalPoster(poster: poster),
                // Festival board link banner
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colors.appBarColor,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: ((context) =>
                              const CommunityPost(boardname: "festivalboard")),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "festivalboard",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "이동",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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