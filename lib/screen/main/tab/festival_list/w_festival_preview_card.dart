import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_style.dart';

/// 카드에 노출할 장르 태그 최대 개수 — 카드가 작아 3개 이상이면 줄바꿈으로 높이가 넘칠 수 있음.
const int _maxGenreTags = 2;

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
    final posterWidth = posterHeight * 2 / 3;
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
              width: posterWidth,
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
          if (festival.genres.isNotEmpty || festival.attendingCount > 0) ...[
            const SizedBox(height: 6),
            _buildTagsRow(colors),
          ],
        ],
      ),
    );
  }

  // 장르 태그는 개수가 가변적이라 Expanded(Wrap)으로 감싸 남은 폭 안에서만 줄바꿈되게 하고,
  // 참석 인원은 고정 길이 텍스트라 그 옆에 남는 공간을 그대로 차지하게 둔다 — Row가 두 가변
  // 콘텐츠를 나란히 놓아도 폭을 넘기지 않는다(Expanded가 먼저 남은 폭을 계산해줌).
  Widget _buildTagsRow(AbstractThemeColors colors) {
    return Row(
      children: [
        if (festival.genres.isNotEmpty) Expanded(child: _buildGenreTags(colors)),
        if (festival.attendingCount > 0) ...[
          const SizedBox(width: 8),
          Icon(Icons.people_outline_rounded, color: colors.activate, size: 14),
          const SizedBox(width: 4),
          Text(
            'attending_count_short'.tr(args: ['${festival.attendingCount}']),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXs,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenreTags(AbstractThemeColors colors) {
    final labels = festival.genres
        .map(genreI18nKey)
        .whereType<String>()
        .take(_maxGenreTags)
        .map((key) => key.tr());
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: labels.map((label) => _GenreTag(label: label, colors: colors)).toList(),
    );
  }
}

class _GenreTag extends StatelessWidget {
  final String label;
  final AbstractThemeColors colors;

  const _GenreTag({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.activate.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusBadge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXxs,
          fontWeight: FontWeight.w600,
          color: colors.activate,
        ),
      ),
    );
  }
}
