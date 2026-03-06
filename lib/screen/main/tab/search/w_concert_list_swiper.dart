import 'dart:ui';

import 'package:card_swiper/card_swiper.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/f_festival_information.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/FestivalPreviewProvider.dart';
import '../../../../model/poster_model.dart';

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
      _currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewProvider = Provider.of<FestivalPreviewProvider>(context);
    final colors = context.appColors;

    if (previewProvider.items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.loadingIndicator,
        ),
      );
    }
    final items = previewProvider.items;
    
    return Stack(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: ResizeImage(
                NetworkImage(
                  items[_currentPage].posterUrl,
                ),
                width: 100,
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: colors.swiperOverlay.withOpacity(0.5),
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
              itemCount: items.length,
              pagination: SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                  activeColor: colors.activate,
                  color: colors.activate.withOpacity(0.3),
                  activeSize: 10,
                  size: 7,
                ),
              ),
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    final poster = PosterModel(
                      id: item.id,
                      title: item.title,
                      description: '',
                      location: item.location,
                      startDate: item.startDate,
                      endDate: '',
                      posterUrl: item.posterUrl,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FestivalInformationFragment(
                              poster: poster)),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.cardShadow.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        item.posterUrl,
                        cacheWidth: 360,
                        fit: BoxFit.fill,
                      ),
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
                  const Offset(-370.0, -40.0),
                  const Offset(0.0, 0.0),
                  const Offset(370.0, -40.0)
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
