import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_star_rating_row.dart';
import 'package:flutter/material.dart';

/// 리뷰 시트의 평점 요약 — 왼쪽 큰 평균 점수, 오른쪽 5~1점 분포 막대.
class ReviewsSummary extends StatelessWidget {
  final double averageRating;
  final int ratingCount;
  final Map<int, int> distribution;

  const ReviewsSummary({
    super.key,
    required this.averageRating,
    required this.ratingCount,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppDimens.space6),
              StarRatingRow(rating: averageRating, size: 16),
              const SizedBox(height: AppDimens.space6),
              Text(
                'reviews_count'.tr(args: ['$ratingCount']),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXxs,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          Expanded(child: _distribution(colors)),
        ],
      ),
    );
  }

  Widget _distribution(AbstractThemeColors colors) {
    final total = distribution.values.fold(0, (a, b) => a + b);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [5, 4, 3, 2, 1].map((star) {
        final count = distribution[star] ?? 0;
        final ratio = total > 0 ? count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
              const SizedBox(width: 3),
              Text(
                '$star',
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXxs,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimens.space6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.barRadius),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: colors.surface,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space6),
              SizedBox(
                width: 22,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeXxs,
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
