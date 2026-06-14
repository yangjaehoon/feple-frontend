import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 수평 스크롤 날짜 선택 탭 바.
/// [allLabel]이 있으면 "전체" 칩을 첫 번째로 표시한다.
/// [labelBuilder]를 생략하면 'yyyy-MM-dd' → 'M/d' 형식으로 변환한다.
class DateTabBar extends StatelessWidget {
  final List<String> dates;
  final String? selectedDate;
  final void Function(String? date) onDateSelected;
  final String? allLabel;
  final EdgeInsetsGeometry padding;
  final String Function(String date)? labelBuilder;

  const DateTabBar({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
    this.allLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 0),
    this.labelBuilder,
  });

  String _label(String date) {
    if (labelBuilder != null) return labelBuilder!(date);
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${int.parse(parts[1])}/${int.parse(parts[2])}';
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          if (allLabel != null)
            _DateChip(
              label: allLabel!,
              selected: selectedDate == null,
              onTap: () => onDateSelected(null),
            ),
          ...dates.map(
            (date) => _DateChip(
              label: _label(date),
              selected: selectedDate == date,
              onTap: () => onDateSelected(date),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animXFast,
        margin: const EdgeInsets.only(right: 8, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? colors.activate : colors.backgroundMain,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppDimens.fontSizeXs,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.textTitle,
          ),
        ),
      ),
    );
  }
}
