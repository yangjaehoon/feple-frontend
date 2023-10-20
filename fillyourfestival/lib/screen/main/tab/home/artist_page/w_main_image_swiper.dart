import 'dart:ui';

import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/screen/main/tab/home/artist_page/w_artist_name_like.dart';
import 'package:flutter/material.dart';

class MainImageSwiper extends StatefulWidget {
  const MainImageSwiper({super.key, required this.artistName});

  final String artistName;

  @override
  State<MainImageSwiper> createState() => _MainImageSwiperState();
}

class _MainImageSwiperState extends State<MainImageSwiper> {
  final List<String> ftvArtImgList = [
    'assets/image/artist_ftv/1.jpg',
    'assets/image/artist_ftv/2.jpg',
    'assets/image/artist_ftv/3.jpg',
    'assets/image/artist_ftv/4.jpg',
    'assets/image/artist_ftv/5.jpg',
    'assets/image/artist_ftv/6.jpg',

    //나중에 아티스트 개인별 페스티벌 정방향(1:1)사진 등록
  ];

  final PageController _pageController = PageController(
    viewportFraction: 0.55,
    //initialPage: 999,
  );

  int _currentPage = 0;

  ValueNotifier<double> _scroll = ValueNotifier(0.0);

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page == null) return;
      _scroll.value = _pageController.page!;
    });

    Timer.periodic(
      Duration(seconds: 2),
          (Timer timer) {
        if (_currentPage < ftvArtImgList.length) {
          _currentPage++;
        }
        else {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_currentPage),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(ftvArtImgList[_currentPage]),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5,
                  sigmaY: 5,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),
          PageView.builder(
            onPageChanged: _onPageChanged,
            controller: _pageController,
            itemCount: ftvArtImgList.length,
            //scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(0,40,0,20),
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _scroll,
                      builder: (context, scroll, child) {
                        final difference = (scroll - index).abs();
                        final scale = 1 - (difference * 0.2);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 8),
                                ),
                              ],
                              image: DecorationImage(
                                image: AssetImage(ftvArtImgList[index]),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          ArtistNameLike(artistName: widget.artistName),
        ],
      ),
    );
  }
}
