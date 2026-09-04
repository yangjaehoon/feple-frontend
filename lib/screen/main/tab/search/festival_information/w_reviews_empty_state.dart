import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 리뷰가 하나도 없을 때 리뷰 시트 본문에 표시하는 안내.
class ReviewsEmptyState extends StatelessWidget {
  const ReviewsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(Icons.star_outline_rounded,
                    color: Colors.amber, size: 32),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space20),
          Text(
            'reviews_no_reviews'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeLg,
              fontWeight: FontWeight.w700,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: AppDimens.space10),
          Text(
            'reviews_empty_hint'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: colors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
