import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 관리자가 실제 셋리스트를 등록하지 않아, 아티스트가 평소 부르는 곡으로
/// 대체 표시 중임을 알리는 배지.
class PredictedSetlistBadge extends StatelessWidget {
  const PredictedSetlistBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusBadge),
      ),
      child: Text(
        'setlist_predicted_badge'.tr(),
        style: TextStyle(
          fontSize: AppDimens.fontSizeTiny,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
