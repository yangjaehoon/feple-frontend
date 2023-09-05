import 'dart:ui';

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

  final PageController _pageController = PageController(
    viewportFraction: 0.55,
    //initialPage: 1000,
  );

  int _currentPage = 0;

  ValueNotifier<double> _scroll = ValueNotifier(0.0);

  void _onPageChanged(int newPage) {
    setState(() {
      //newPage = newPage % posterList.length;
      _currentPage = newPage;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(
      () {
        if (_pageController.page == null) return;
        _scroll.value = _pageController.page!;
      },
    );

    Timer.periodic(
      Duration(seconds: 2),
      (Timer timer) {
        if (_currentPage < posterList.length) {
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
      height: 300,
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_currentPage),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(posterList[_currentPage]),
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
            itemCount: posterList.length,
            itemBuilder: (context, index) {
              //index = index % posterList.length;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _scroll,
                    builder: (context, scroll, child) {
                      print(scroll);
                      //print(index);
                      final difference = (scroll - index).abs();
                      final scale = 1 - (difference * 0.2);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          height: 254.5,
                          width: 180,
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
                              image: AssetImage(posterList[index]),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
