import 'package:cached_network_image/cached_network_image.dart';

import 'package:card_swiper/card_swiper.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';
import '../../../../model/festival_preview.dart';

class ConcertListSwiperWidget extends StatefulWidget {
  const ConcertListSwiperWidget({super.key});

  @override
  State<ConcertListSwiperWidget> createState() =>
      _ConcertListSwiperWidgetState();
}

class _ConcertListSwiperWidgetState extends State<ConcertListSwiperWidget> {
  int _currentPage = 0;

  void _onPageChanged(int newPage) {
    setState(() => _currentPage = newPage);
  }

  Widget _buildBlurBackground(AbstractThemeColors colors, String posterUrl) {
    // 100px ResizeImage는 늘릴 때 자연스럽게 흐려짐 — BackdropFilter GPU offscreen 불필요
    return ClipRect(
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: ResizeImage(CachedNetworkImageProvider(posterUrl), width: 100),
              fit: BoxFit.cover,
            ),
            ColoredBox(color: colors.swiperOverlay.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwiperContent(AbstractThemeColors colors, List<FestivalPreview> items) {
    return SizedBox(
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
            fontSize: AppDimens.fontSizeSm,
            activeFontSize: 15,
          ),
        ),
        itemBuilder: (BuildContext context, int index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(builder: (context) => FestivalInformationFragment(
                  poster: item.toModel(),
                  heroTag: 'swiper_fp_${item.id}',
                )),
              );
            },
            child: Hero(
              tag: 'swiper_fp_${item.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl,
                    memCacheWidth: 360,
                    fit: BoxFit.fill,
                    fadeInDuration: AppDimens.animXFast,
                    fadeOutDuration: AppDimens.animTapFeedback,
                    placeholder: (context, url) => const SkeletonBox(height: double.infinity),
                    errorWidget: (context, url, error) {
                      final colors = context.appColors;
                      return Container(
                        color: colors.surface,
                        child: Icon(Icons.broken_image_rounded,
                            size: 36, color: colors.textSecondary.withValues(alpha: 0.4)),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
        layout: SwiperLayout.CUSTOM,
        customLayoutOption: CustomLayoutOption(startIndex: -1, stateCount: 3)
          ..addRotate([-45.0 / 180, 0.0, 45.0 / 180])
          ..addTranslate([
            const Offset(-370.0, -20.0),
            const Offset(0.0, 0.0),
            const Offset(370.0, -20.0),
          ]),
        itemWidth: 180,
        itemHeight: 254.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingEmpty = context.select<FestivalPreviewProvider, bool>(
        (p) => p.isLoading && p.items.isEmpty);
    final isErrorEmpty = context.select<FestivalPreviewProvider, bool>(
        (p) => p.error != null && p.items.isEmpty);
    final allItems = context.select<FestivalPreviewProvider, List<FestivalPreview>>(
        (p) => p.items);
    final colors = context.appColors;

    if (isLoadingEmpty) return _buildSkeleton();
    if (isErrorEmpty) return _buildError(context);

    final items = allItems.where((f) => !f.isEnded).toList();
    if (items.isEmpty) return _buildEmpty(colors);

    final safeCurrentPage = _currentPage.clamp(0, items.length - 1);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildBlurBackground(colors, items[safeCurrentPage].posterUrl),
        _buildSwiperContent(colors, items),
      ],
    );
  }

  Widget _buildSkeleton() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          SkeletonBox(height: 300, borderRadius: BorderRadius.zero),
          Center(
            child: SkeletonBox(
              width: 180,
              height: 254.5,
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
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
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: ErrorState(
          message: 'err_fetch_data'.tr(),
          onRetry: () => context.read<FestivalPreviewProvider>().refresh(),
        ),
      ),
    );
  }

  Widget _buildEmpty(AbstractThemeColors colors) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.festival_rounded,
              size: 40, color: colors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(
            'no_upcoming_festivals'.tr(),
            style: TextStyle(
                fontSize: AppDimens.fontSizeMd,
                color: colors.textSecondary.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
