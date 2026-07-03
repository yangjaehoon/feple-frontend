import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

import 'package:feple/model/festival_preview.dart';

class FestivalPreviewCard extends StatelessWidget {
  final FestivalPreview festival;
  final String? heroTag;

  const FestivalPreviewCard({super.key, required this.festival, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // 기준 390px: 카드 높이 140(0.359), 포스터 높이 120(0.308)
    final cardHeight = screenWidth * 0.359;
    final posterHeight = screenWidth * 0.308;

    return SurfaceCard(
      child: SizedBox(
        height: cardHeight,
        child: Row(
          children: [
            _buildPoster(posterHeight),
            Expanded(child: _buildInfo(colors, context.isEnglish)),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(double posterHeight) {
    // aspect ratio 2:3 → 너비는 posterHeight * (2/3)으로 자동 계산됨
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              imageUrl: festival.posterUrl,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            if (festival.isEnded) ...[
              Container(color: Colors.black.withValues(alpha: 0.5)),
              Center(
                child: Text(
                  'status_ended'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
            if (!festival.isEnded && festival.dDaysUntil != null)
              Positioned(
                top: 6,
                left: 6,
                child: DayBadge(dDays: festival.dDaysUntil!),
              ),
          ],
        ),
      ),
    );

    return Container(
      height: posterHeight,
      margin: const EdgeInsets.all(10),
      child: heroTag != null ? Hero(tag: heroTag!, child: inner) : inner,
    );
  }

  Widget _buildInfo(AbstractThemeColors colors, bool isEnglish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            festival.displayTitle(isEnglish),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: AppDimens.fontSizeXl,
              color: colors.textTitle,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: colors.activate, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  festival.location,
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeXs,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: colors.activate, size: 14),
              const SizedBox(width: 4),
              Text(
                festival.startDate,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
