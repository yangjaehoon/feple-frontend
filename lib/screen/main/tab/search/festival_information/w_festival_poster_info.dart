import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_star_rating_row.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_notifier.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_style.dart';
import 'package:flutter/material.dart';

/// 포스터 썸네일 + 제목·태그·일정·장소 + 참석 행 + 초기화 에러 재시도 + 평점 배지.
/// [FestivalPosterNotifier]를 직접 받는다 — 참석/초기화에러/평점은 각각의 좁은
/// 리스너블로 개별 구독해야 리빌드 범위가 최소화되기 때문(포스터 UI facade).
class FestivalPosterInfo extends StatelessWidget {
  final FestivalPosterNotifier notifier;
  final String? heroTag;
  final VoidCallback onKakaoMap;
  final VoidCallback onToggleAttending;
  final VoidCallback onShowReviews;

  const FestivalPosterInfo({
    super.key,
    required this.notifier,
    required this.heroTag,
    required this.onKakaoMap,
    required this.onToggleAttending,
    required this.onShowReviews,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // 2:3 비율(120x180 기준) 유지하며 화면 너비에 비례.
    final posterWidth = ResponsiveSize(context).w(120);
    final posterHeight = posterWidth * 1.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(colors, posterWidth, posterHeight),
          const SizedBox(width: AppDimens.space16),
          Expanded(child: _infoColumn(context, colors)),
        ],
      ),
    );
  }

  Widget _thumbnail(AbstractThemeColors colors, double width, double height) {
    final child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        boxShadow: CardShadows.elevated(colors),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        child: CachedNetworkImage(
          imageUrl: notifier.poster.posterUrl,
          memCacheWidth: 300,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const SkeletonBox(height: double.infinity),
          errorWidget: (_, _, _) => Container(
            color: colors.surface,
            child: Icon(
              Icons.broken_image_rounded,
              size: 32,
              color: colors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
    if (heroTag == null) return child;
    return Hero(tag: heroTag!, child: child);
  }

  Widget _infoColumn(BuildContext context, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimens.space4),
        Text(
          notifier.poster.displayTitle(context.isEnglish),
          softWrap: true,
          style: const TextStyle(
            fontSize: AppDimens.fontSizeTitle,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        _tagRow(),
        const SizedBox(height: AppDimens.space8),
        _infoRow(
          icon: Icons.calendar_today_rounded,
          color: colors.accentColor,
          child: Text(
            notifier.poster.endDate.isNotEmpty
                ? '${notifier.poster.startDate} ~ ${notifier.poster.endDate}'
                : notifier.poster.startDate,
            style: const TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space6),
        GestureDetector(
          onTap: onKakaoMap,
          child: _infoRow(
            icon: Icons.location_on_rounded,
            color: colors.accentColor,
            child: Text(
              notifier.poster.location,
              softWrap: true,
              style: const TextStyle(
                fontSize: AppDimens.fontSizeMd,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        _infoColumnBottom(colors),
      ],
    );
  }

  // 참석 행은 attendingChanges로, 초기화 에러/평점은 전체 notifier로 개별 구독 —
  // 서로의 변경이 상대를 리빌드시키지 않도록.
  Widget _infoColumnBottom(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: notifier.attendingChanges,
          builder: (_, _) => _attendingRow(colors),
        ),
        ListenableBuilder(
          listenable: notifier,
          builder: (_, _) => notifier.hasInitError
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _initErrorRow(),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppDimens.space6),
        ListenableBuilder(
          listenable: notifier,
          builder: (_, _) => _ratingBadge(),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: AppDimens.space6),
        Expanded(child: child),
      ],
    );
  }

  Widget _tagRow() {
    final tags = <Widget>[];
    for (final genre in notifier.poster.genres) {
      final key = genreI18nKey(genre);
      if (key == null) continue;
      tags.add(_Tag(label: key.tr()));
    }
    final age = notifier.poster.ageRestriction;
    if (age != null && age != 'NONE') {
      final key = ageI18nKey(age);
      if (key != null) {
        tags.add(_Tag(label: key.tr(), color: ageDisplayColor(age)));
      }
    }
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: tags);
  }

  Widget _attendingRow(AbstractThemeColors colors) {
    final count = notifier.attendingCount;
    final isAttending = notifier.attending;
    return Row(
      children: [
        Icon(Icons.people_outline_rounded, color: colors.accentColor, size: 14),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            count > 0
                ? 'attending_count'.tr(args: ['$count'])
                : 'attend_none'.tr(),
            style: const TextStyle(
              fontSize: AppDimens.fontSizeSm,
              color: Colors.white70,
            ),
          ),
        ),
        GestureDetector(
          onTap: onToggleAttending,
          child: AnimatedContainer(
            duration: AppDimens.animFast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isAttending
                  ? colors.accentColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              border: Border.all(
                color: isAttending
                    ? colors.accentColor
                    : Colors.white.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Text(
              'attend_toggle'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                fontWeight: FontWeight.w600,
                color: isAttending ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initErrorRow() {
    return GestureDetector(
      onTap: notifier.retryInit,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync_problem_rounded,
              size: 13, color: Colors.white54),
          const SizedBox(width: AppDimens.space4),
          Text(
            'retry'.tr(),
            style: const TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: Colors.white54,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBadge() {
    if (!notifier.ratingLoaded) return const SizedBox.shrink();
    if (notifier.ratingLoadFailed) return const SizedBox.shrink();

    final hasRating = notifier.ratingCount > 0;
    final label = hasRating
        ? 'rating_average_label'.tr(
            args: [
              notifier.averageRating.toStringAsFixed(1),
              notifier.ratingCount.toString(),
            ],
          )
        : 'reviews_no_reviews'.tr();
    final content = hasRating
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRatingRow(rating: notifier.averageRating, size: 18),
              const SizedBox(width: AppDimens.space4),
              Text(
                '(${notifier.ratingCount})',
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXxs,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (_) => const Icon(Icons.star_outline_rounded,
                  color: Colors.white60, size: 18),
            ),
          );

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onShowReviews,
        // 별 아이콘/텍스트만큼만 히트 영역이 생기면 최소 터치 타겟보다 작아지므로
        // 세로로 최소 44dp를 확보한다.
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppDimens.minTouchTarget),
          child: Align(alignment: Alignment.centerLeft, child: content),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
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
