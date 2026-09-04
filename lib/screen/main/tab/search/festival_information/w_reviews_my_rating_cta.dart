import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:flutter/material.dart';

/// 리뷰 시트 상단의 "내 별점" CTA 카드 — 인증 상태에 따라 4가지 모습:
/// 대기중 안내 / 미인증(인증하러 가기) / 제출 중 로딩 / 인증됨(별점 남기기·수정).
class ReviewsMyRatingCta extends StatelessWidget {
  final PosterCertState certState;
  final bool isSubmittingRating;
  final int? myRating;
  final VoidCallback onCertTap;
  final VoidCallback onRatingTap;

  const ReviewsMyRatingCta({
    super.key,
    required this.certState,
    required this.isSubmittingRating,
    required this.myRating,
    required this.onCertTap,
    required this.onRatingTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: switch (certState) {
        PosterCertState.pending => _pending(colors),
        PosterCertState.none => _noCert(colors),
        PosterCertState.certified =>
          isSubmittingRating ? _loading(colors) : _certified(colors),
      },
    );
  }

  Widget _pending(AbstractThemeColors colors) => Row(
        children: [
          Icon(Icons.hourglass_top_rounded,
              color: colors.textSecondary, size: 16),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: Text(
              'reviews_cert_pending'.tr(),
              style: TextStyle(
                  fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
            ),
          ),
        ],
      );

  Widget _noCert(AbstractThemeColors colors) => Row(
        children: [
          Icon(Icons.workspace_premium_outlined,
              color: colors.certRingColor, size: 16),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: Text(
              'reviews_cert_prompt'.tr(),
              style: TextStyle(
                  fontSize: AppDimens.fontSizeSm, color: colors.textTitle),
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          TextButton(
            onPressed: onCertTap,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'reviews_cert_btn'.tr(),
              style: TextStyle(
                color: colors.activate,
                fontWeight: FontWeight.w700,
                fontSize: AppDimens.fontSizeSm,
              ),
            ),
          ),
        ],
      );

  Widget _loading(AbstractThemeColors colors) => SizedBox(
        height: 24,
        child: Center(
          child: CircularProgressIndicator(
              color: colors.activate, strokeWidth: 2),
        ),
      );

  Widget _certified(AbstractThemeColors colors) => Row(
        children: [
          Icon(Icons.workspace_premium_rounded,
              color: colors.certRingColor, size: 16),
          const SizedBox(width: AppDimens.space8),
          Text(
            'reviews_my_rating'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: colors.textTitle,
            ),
          ),
          if (myRating != null) ...[
            const SizedBox(width: AppDimens.space8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < myRating!
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 14,
                ),
              ),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: onRatingTap,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              myRating != null
                  ? 'reviews_edit_rating'.tr()
                  : 'reviews_leave_rating'.tr(),
              style: TextStyle(
                color: colors.activate,
                fontWeight: FontWeight.w700,
                fontSize: AppDimens.fontSizeSm,
              ),
            ),
          ),
        ],
      );
}
