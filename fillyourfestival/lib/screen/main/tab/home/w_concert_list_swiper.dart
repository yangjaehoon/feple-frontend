import 'dart:ui';

import 'package:card_swiper/card_swiper.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/f_festival_information.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/poster/poster_provider.dart';

class ConcertListSwiperWidget extends StatefulWidget {
  const ConcertListSwiperWidget({super.key});

  @override
  State<ConcertListSwiperWidget> createState() =>
      _ConcertListSwiperWidgetState();
}

class _ConcertListSwiperWidgetState extends State<ConcertListSwiperWidget> {
  int _currentPage = 0;

  void _onPageChanged(int newPage) {
    setState(() {
      if (_currentPage != null) {
        _currentPage = newPage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final poster = Provider.of<PosterProvider>(context);

    //if (poster.posters == null || poster.posters.isEmpty) {
    if (poster.posters.isEmpty) {
      // poster.posters가 비어 있다면 또는 null이면 로딩 중을 나타내는 UI를 반환
      return CircularProgressIndicator();
    }
    return Stack(
      children: [
        Container(
          //포스터 뒷배경 blur처리한 화면
          height: 300,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                //posterList[_currentPage],
                poster.posters[_currentPage].posterUrl,
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
            child: Swiper(
              onIndexChanged: _onPageChanged,
              viewportFraction: 0.8,
              scale: 0.6,
              autoplay: true,
              duration: 300,
              itemCount: poster.posters.length,
              pagination: const SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                  activeColor: Colors.blue,
                  color: Colors.grey,
                ),
              ),
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FestivalInformationFragment(
                              poster: poster.posters[index])),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      poster.posters[index].posterUrl,
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              },
              layout: SwiperLayout.CUSTOM,
              customLayoutOption: CustomLayoutOption(
                startIndex: -1,
                stateCount: 3,
              )
                ..addRotate([-45.0 / 180, 0.0, 45.0 / 180])
                ..addTranslate([
                  Offset(-370.0, -40.0),
                  Offset(0.0, 0.0),
                  Offset(370.0, -40.0)
                ]),
              itemWidth: 180,
              itemHeight: 254.5,
            ),
          ),
        ),
      ],
    );
  }
}
