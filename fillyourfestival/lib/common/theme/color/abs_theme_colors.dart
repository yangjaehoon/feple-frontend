import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

export 'package:fast_app_base/common/constant/app_colors.dart';

typedef ColorProvider = Color Function();

abstract class AbstractThemeColors {
  const AbstractThemeColors();

  Color get seedColor => AppColors.skyBlue;

  Color get veryBrightGrey => AppColors.brightGrey;

  Color get drawerBg => AppColors.surfaceWhite;

  Color get scrollableItem => AppColors.textMain;

  Color get iconButton => AppColors.skyBlue;

  Color get iconButtonInactivate => AppColors.textMuted;

  Color get inActivate => const Color.fromARGB(255, 200, 207, 220);

  Color get activate => AppColors.skyBlue;

  Color get badgeBg => AppColors.sunnyYellow;

  Color get textBadgeText => AppColors.textMain;

  Color get badgeBorder => Colors.transparent;

  Color get divider => const Color.fromARGB(255, 238, 238, 238);

  Color get text => AppColors.textMain;

  Color get hintText => AppColors.textMuted;

  Color get focusedBorder => AppColors.skyBlue;

  Color get confirmText => AppColors.skyBlue;

  Color get drawerText => AppColors.textMain;

  Color get snackbarBgColor => AppColors.skyBlue;

  Color get blueButtonBackground => AppColors.skyBlue;

  Color get appBarBackground => AppColors.skyBlue;
}
