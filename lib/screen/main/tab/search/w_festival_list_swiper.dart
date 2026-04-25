import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:card_swiper/card_swiper.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';
import '../../../../model/festival_model.dart';

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
      return SizedBox(
        height: 300,
        child: Stack(
          children: [
            SkeletonBox(height: 300, borderRadius: BorderRadius.zero),
            Center(
              child: SkeletonBox(
                width: 180,
                height: 254.5,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: SkeletonBox(
                  width: 48,
                  height: 14,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final items = previewProvider.items;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRect(
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ResizeImage(
                  CachedNetworkImageProvider(
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
                color: colors.swiperOverlay.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: Swiper(
            onIndexChanged: _onPageChanged,
            viewportFraction: 0.8,
            scale: 0.6,
            autoplay: true,
            duration: 300,
            itemCount: items.length,
            pagination: const SwiperPagination(
              margin: EdgeInsets.only(bottom: 0),
              builder: FractionPaginationBuilder(
                color: Colors.white54,
                activeColor: Colors.white,
                fontSize: 13,
                activeFontSize: 15,
              ),
            ),
            itemBuilder: (BuildContext context, int index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  final poster = FestivalModel(
                    id: item.id,
                    title: item.title,
                    description: item.description,
                    location: item.location,
                    startDate: item.startDate,
                    endDate: item.endDate ?? '',
                    posterUrl: item.posterUrl,
                    latitude: item.latitude,
                    longitude: item.longitude,
                  );
                  Navigator.push(
                    context,
                    SlideRoute(
                        builder: (context) =>
                            FestivalInformationFragment(poster: poster)),
                  );
                },
                child: Hero(
                  tag: 'festival_poster_${item.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.cardShadow.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: item.posterUrl,
                        memCacheWidth: 360,
                        fit: BoxFit.fill,
                        placeholder: (context, url) => const SkeletonBox(height: double.infinity),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
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
                const Offset(-370.0, -20.0),
                const Offset(0.0, 0.0),
                const Offset(370.0, -20.0)
              ]),
            itemWidth: 180,
            itemHeight: 254.5,
          ),
        ),
      ],
    );
  }
}
