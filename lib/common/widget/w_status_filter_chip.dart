import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 상태별 색상이 다른 필터 칩 (인증/신청 목록 등에서 공용으로 사용).
class StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final ValueChanged<bool> onSelected;

  const StatusFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        selectedColor: selectedColor.withValues(alpha: 0.12),
        checkmarkColor: selectedColor,
        backgroundColor: colors.surface,
        side: BorderSide(
          color: selected ? selectedColor : colors.textSecondary.withValues(alpha: 0.28),
          width: selected ? 1.5 : 1.0,
        ),
        labelStyle: TextStyle(
          fontSize: AppDimens.fontSizeSm,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? selectedColor : colors.textSecondary,
        ),
        shape: const StadiumBorder(),
        // 44px 최소 터치 타겟 확보 위해 visualDensity.compact 제거, 수직 패딩 확대
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}
