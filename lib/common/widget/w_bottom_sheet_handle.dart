import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.textSecondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppDimens.barRadius),
        ),
      ),
    );
  }
}
