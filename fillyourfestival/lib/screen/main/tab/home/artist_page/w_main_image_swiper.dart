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

  final PageController _pageController = PageController(
    viewportFraction: 0.6,
  );


  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: ftvArtImgList.length,
            //scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(ftvArtImgList[index])
                        )
                      ),
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
