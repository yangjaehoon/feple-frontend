import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 상태 뱃지(색상 점 + 라벨) — 인증/신청곡 내역 등 "내 활동" 목록에서 공용으로 사용.
class StatusBadge extends StatelessWidget {
  final Color color;
  final String label;
  final double backgroundAlpha;
  final double borderRadius;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.color,
    required this.label,
    this.backgroundAlpha = 0.12,
    this.borderRadius = AppDimens.cardRadiusTiny,
    this.fontSize = AppDimens.fontSizeXxs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: AppDimens.space4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
