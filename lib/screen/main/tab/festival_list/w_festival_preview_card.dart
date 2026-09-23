import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:flutter/material.dart';

import 'package:feple/screen/main/tab/search/festival_information/festival_poster_style.dart';
import 'package:feple/model/festival_preview.dart';

/// 카드에 노출할 장르 태그 최대 개수 — 카드가 작아 3개 이상이면 줄바꿈으로 높이가 넘칠 수 있음.
const int _maxGenreTags = 2;

class FestivalPreviewCard extends StatelessWidget {
  final FestivalPreview festival;
  final String? heroTag;

  const FestivalPreviewCard({super.key, required this.festival, this.heroTag});

  /// 기준 390px: 카드 높이 140, 포스터 높이 120. 로딩 스켈레톤이 같은 값을 써야
  /// 전환 시 높이가 튀지 않으므로 static으로 노출한다. MediaQuery 폭에 직접
  /// 비례시키지 않는 이유는 ResponsiveSize의 대화면 상한 클램프를 그대로 따르기 위함.
  static double cardHeightOf(BuildContext context) =>
      ResponsiveSize(context).w(140);
  static double posterHeightOf(BuildContext context) =>
      ResponsiveSize(context).w(120);

  /// 포스터 가로세로 비율(2:3) — 너비는 높이로부터 계산된다.
  static const double posterAspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final cardHeight = cardHeightOf(context);
    final posterHeight = posterHeightOf(context);

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
    final posterWidth = posterHeight * posterAspectRatio;
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      child: AspectRatio(
        aspectRatio: posterAspectRatio,
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
    final genreLabels = _genreLabels();
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
          const SizedBox(height: AppDimens.space6),
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: colors.activate, size: 14),
              const SizedBox(width: AppDimens.space4),
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
          const SizedBox(height: AppDimens.space4),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: colors.activate, size: 14),
              const SizedBox(width: AppDimens.space4),
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
          if (genreLabels.isNotEmpty || festival.attendingCount > 0) ...[
            const SizedBox(height: AppDimens.space6),
            _buildTagsRow(colors, genreLabels),
          ],
        ],
      ),
    );
  }

  // 매핑 안 되는 장르 코드는 여기서 걸러지므로, 위 _buildInfo의 표시 여부 가드도
  // 이 필터링된 라벨 목록을 그대로 써야 한다 — 원본 genres 리스트 기준으로 판단하면
  // 전부 매핑 실패한 코드만 있을 때 빈 줄바꿈 영역만 그려지는 죽은 공간이 생긴다.
  List<String> _genreLabels() => festival.genres
      .map(genreI18nKey)
      .whereType<String>()
      .take(_maxGenreTags)
      .map((key) => key.tr())
      .toList();

  // 장르 태그는 개수가 가변적이라 Expanded(Wrap)으로 감싸 남은 폭 안에서만 줄바꿈되게 하고,
  // 참석 인원은 고정 길이 텍스트라 그 옆에 남는 공간을 그대로 차지하게 둔다 — Row가 두 가변
  // 콘텐츠를 나란히 놓아도 폭을 넘기지 않는다(Expanded가 먼저 남은 폭을 계산해줌).
  Widget _buildTagsRow(AbstractThemeColors colors, List<String> genreLabels) {
    return Row(
      children: [
        if (genreLabels.isNotEmpty) Expanded(child: _buildGenreTags(colors, genreLabels)),
        if (festival.attendingCount > 0) ...[
          const SizedBox(width: AppDimens.space8),
          Icon(Icons.people_outline_rounded, color: colors.activate, size: 14),
          const SizedBox(width: AppDimens.space4),
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

  Widget _buildGenreTags(AbstractThemeColors colors, List<String> labels) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: labels.map((label) => _GenreTag(label: label, color: colors.activate)).toList(),
    );
  }
}

class _GenreTag extends StatelessWidget {
  final String label;
  final Color color;

  const _GenreTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusBadge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXxs,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
