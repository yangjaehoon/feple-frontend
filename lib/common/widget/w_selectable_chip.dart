import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/dart/extension/context_extension.dart';
import 'package:flutter/material.dart';

class SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;
  final Color? unselectedTextColor;

  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.margin = const EdgeInsets.only(right: 8),
    this.unselectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animXFast,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.activate : colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Theme.of(context).colorScheme.onPrimary : (unselectedTextColor ?? colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// "전체" + [values] 각각의 SelectableChip을 한 줄로 나열 — 홈/검색탭의
/// 단색 필터 칩 행(상태별 색상이 다른 [StatusFilterChipRow]와는 별개)에서
/// 반복되던 SizedBox(36)+가로 ListView 뼈대를 공용화.
class SelectableChipRow<T> extends StatelessWidget {
  final List<T> values;
  final T? selected;
  final String allLabel;
  final String Function(T value) labelOf;
  final ValueChanged<T?> onChanged;

  const SelectableChipRow({
    super.key,
    required this.values,
    required this.selected,
    required this.allLabel,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          SelectableChip(
            label: allLabel,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final value in values)
            SelectableChip(
              label: labelOf(value),
              selected: selected == value,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}
