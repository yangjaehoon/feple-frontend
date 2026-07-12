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

/// "전체" + [values] 각각의 필터 칩을 한 줄로 나열 (인증/신청 목록 등에서 공용).
/// 상태 enum의 label/색상은 호출부가 이미 가진 *_status_style.dart extension을
/// 그대로 전달받아 쓰므로, 새 상태값 추가 시 enum + style extension만 고치면
/// 칩 목록도 자동으로 늘어남 — 화면마다 칩을 손으로 나열하지 않아도 됨.
class StatusFilterChipRow<T extends Object> extends StatelessWidget {
  final List<T> values;
  final T? selected;
  final String allLabel;
  final String Function(T value) labelOf;
  final Color Function(T value, AbstractThemeColors colors) colorOf;
  final ValueChanged<T?> onChanged;

  const StatusFilterChipRow({
    super.key,
    required this.values,
    required this.selected,
    required this.allLabel,
    required this.labelOf,
    required this.colorOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          StatusFilterChip(
            label: allLabel,
            selected: selected == null,
            selectedColor: colors.activate,
            onSelected: (_) => onChanged(null),
          ),
          for (final value in values)
            StatusFilterChip(
              label: labelOf(value),
              selected: selected == value,
              selectedColor: colorOf(value, colors),
              onSelected: (_) => onChanged(value),
            ),
        ],
      ),
    );
  }
}
