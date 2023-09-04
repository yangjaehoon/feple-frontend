import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';

import '../../../../../common/constant/app_colors.dart';

class MainImageSwiper extends StatefulWidget {
  const MainImageSwiper({super.key});

  @override
  State<MainImageSwiper> createState() => _MainImageSwiperState();
}

class _MainImageSwiperState extends State<MainImageSwiper> {
  final List<String> ftvArtImgList = [
    'assets/image/poster/hiphopplaya_poster.jpg',
    'assets/image/poster/psy_poster.jpg',
    'assets/image/poster/rapbeat_poster.jpg',
    'assets/image/poster/waterbomb_poster.jpg',
    //나중에 아티스트 개인별 페스티벌 정방향(1:1)사진 등록
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
            itemCount: ftvArtImgList.length,
            autoplay: true,
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                children: [
                  Image.asset(
                    ftvArtImgList[index],
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
              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Swiper(
                outer: true,
                itemCount: ftvArtImgList.length,
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
                  return Image.asset(ftvArtImgList[index]);
                }, //control: SwiperControl(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
