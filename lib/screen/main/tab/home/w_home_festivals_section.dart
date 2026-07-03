import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class HomeFestivalsSection extends StatelessWidget {
  const HomeFestivalsSection({
    super.key,
    required this.festivals,
    required this.onTap,
    this.hasError = false,
    this.onRetry,
  });

  final List<FestivalModel>? festivals;
  final void Function(FestivalModel) onTap;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: onRetry),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    // 기준 390px: 카드 너비 130(1/3), 카드 높이 195(0.5)
    final cardWidth = screenWidth / 3;
    final cardHeight = screenWidth * 0.5;
    final itemExtent = cardWidth + 12;

    if (festivals == null) {
      return SizedBox(
        height: cardHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemExtent: itemExtent,
          itemCount: 4,
          itemBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SkeletonBox(
              width: cardWidth,
              height: cardHeight,
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
            ),
          ),
        ),
      );
    }
    if (festivals!.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'no_liked_festivals'.tr(),
      );
    }
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemExtent: itemExtent,
        itemCount: festivals!.length,
        itemBuilder: (_, index) => _FestivalItem(
          key: ValueKey(festivals![index].id),
          festival: festivals![index],
          onTap: onTap,
        ),
      ),
    );
  }
}

class _FestivalItem extends StatelessWidget {
  const _FestivalItem({super.key, required this.festival, required this.onTap});

  final FestivalModel festival;
  final void Function(FestivalModel) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final cardWidth = MediaQuery.sizeOf(context).width / 3;
    return TapScale(
      onTap: () => onTap(festival),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(colors),
              _buildTitleOverlay(context.isEnglish),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(AbstractThemeColors colors) {
    return CachedNetworkImage(
      imageUrl: festival.posterUrl,
      memCacheWidth: 260,
      fit: BoxFit.cover,
      fadeInDuration: AppDimens.animXFast,
      fadeOutDuration: AppDimens.animTapFeedback,
      placeholder: (_, _) => Container(color: colors.surface),
      errorWidget: (_, _, _) => Container(
        color: colors.surface,
        child: Icon(Icons.image_not_supported_rounded, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildTitleOverlay(bool isEnglish) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      // BackdropFilter(blur) 제거 — 스크롤 중 매 프레임 GPU offscreen 합성 유발
      // LinearGradient만으로 가독성은 동일하게 유지
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.82),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Text(
          festival.displayTitle(isEnglish),
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppDimens.fontSizeSm,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
