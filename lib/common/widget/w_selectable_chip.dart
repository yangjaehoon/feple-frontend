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
