import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class DayBadge extends StatelessWidget {
  final int dDays;
  const DayBadge({super.key, required this.dDays});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final String label;
    final Color color;

    if (dDays < 0) {
      label = 'festival_ongoing'.tr();
      color = colors.statusOngoingColor;
    } else if (dDays == 0) {
      label = 'd_day'.tr();
      color = colors.error;
    } else if (dDays <= 7) {
      label = 'D-$dDays';
      color = colors.activate;
    } else {
      label = 'D-$dDays';
      color = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusBadge),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppDimens.fontSizeTiny,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
