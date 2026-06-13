import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

import 'package:feple/model/festival_preview.dart';

class FestivalPreviewCard extends StatelessWidget {
  final FestivalPreview festival;

  const FestivalPreviewCard({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPoster(colors),
          Expanded(child: _buildInfo(colors, context.locale.languageCode == 'en')),
        ],
      ),
    );
  }

  Widget _buildPoster(AbstractThemeColors colors) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(10),
      child: Hero(
        tag: 'festival_poster_${festival.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  imageUrl: festival.posterUrl,
                  fit: BoxFit.fill,
                ),
                if (festival.isEnded) ...[
                  Container(color: Colors.black.withValues(alpha: 0.5)),
                  Center(
                    child: Text(
                      'status_ended'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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
                    child: _DayBadge(dDays: festival.dDaysUntil!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(AbstractThemeColors colors, bool isEnglish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  festival.displayTitle(isEnglish),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: colors.textTitle,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
                    fontSize: 12,
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
                  fontSize: 12,
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

class _DayBadge extends StatelessWidget {
  final int dDays;
  const _DayBadge({required this.dDays});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final String label;
    final Color color;

    if (dDays < 0) {
      label = 'festival_ongoing'.tr();
      color = colors.statusOngoingColor;
    } else if (dDays == 0) {
      label = 'd_day'.tr();
      color = AppColors.errorRed;
    } else if (dDays <= 7) {
      label = 'D-$dDays';
      color = colors.activate;
    } else {
      label = 'D-$dDays';
      color = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
