import 'dart:ui';

import 'package:card_swiper/card_swiper.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

class ConcertListSwiper extends StatefulWidget {
  const ConcertListSwiper({super.key});

  @override
  State<ConcertListSwiper> createState() => _ConcertListSwiperState();
}

class _ConcertListSwiperState extends State<ConcertListSwiper> {
  final List<String> posterList = [
    'assets/image/poster/hiphopplaya_poster.jpg',
    'assets/image/poster/psy_poster.jpg',
    'assets/image/poster/rapbeat_poster.jpg',
    'assets/image/poster/waterbomb_poster.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        children: [
          Swiper(
            scale: 0.9,
            //viewportFraction: 0.9,
            itemCount: posterList.length,
            autoplay: true,
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                children: [
                  Image.asset(
                    posterList[index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(
            //color: AppColors.grey, //이걸로 사이즈 확인
            //height: 350,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Swiper(
                outer: true,
                itemCount: posterList.length,
                viewportFraction: 0.6,
                // 위젯크기(포스터 크기)
                scale: 0.8,
                // 사진간의 간격
                pagination: const SwiperPagination(
                  alignment: Alignment.bottomCenter,
                  margin: EdgeInsets.all(10),
                  builder: DotSwiperPaginationBuilder(
                    size: 5.0,
                    space: 3.0,
                    activeColor: AppColors.brightBlue,
                    color: AppColors.middleGrey,
                  ),
                ),
                autoplay: true,
                autoplayDisableOnInteraction: true,
                // autoplay is disabled when use swipes.
                itemBuilder: (BuildContext context, int index) {
                  return Image.asset(posterList[index]);
                }, //control: SwiperControl(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
