import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/my_page/w_status_badge.dart';
import 'package:flutter/material.dart';

/// 관리자가 실제 셋리스트를 등록하지 않아, 아티스트가 평소 부르는 곡으로
/// 대체 표시 중임을 알리는 배지.
class PredictedSetlistBadge extends StatelessWidget {
  const PredictedSetlistBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return StatusBadge(
      color: colors.textSecondary,
      label: 'setlist_predicted_badge'.tr(),
      fontSize: AppDimens.fontSizeTiny,
    );
  }
}

/// 라벨(아티스트명/곡 수 등) 옆에 [predicted]일 때만 [PredictedSetlistBadge]를
/// 붙이는 Row — 미리보기 카드와 전체화면 양쪽에서 동일한 배치 로직을 공유.
class SetlistLabelWithPredictedBadge extends StatelessWidget {
  final Widget label;
  final bool predicted;

  const SetlistLabelWithPredictedBadge({
    super.key,
    required this.label,
    required this.predicted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: label),
        if (predicted) ...[
          const SizedBox(width: 6),
          const PredictedSetlistBadge(),
        ],
      ],
    );
  }
}
