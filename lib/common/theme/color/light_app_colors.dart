import 'package:fast_app_base/common/theme/color/abs_theme_colors.dart';
import 'package:flutter/material.dart';

class LightAppColors extends AbstractThemeColors {
  const LightAppColors();

  @override
  Color get seedColor => AppColors.skyBlue;

  @override
  Color get drawerBg => AppColors.surfaceWhite;

  @override
  Color get iconButton => AppColors.skyBlue;

  @override
  Color get iconButtonInactivate => AppColors.textMuted;

  @override
  Color get text => AppColors.textMain;

  @override
  Color get hintText => AppColors.textMuted;

  @override
  Color get divider => const Color(0xFFEEEEEE);

  @override
  Color get appBarBackground => AppColors.skyBlue;

  @override
  Color get activate => AppColors.skyBlue;

  @override
  Color get badgeBg => AppColors.sunnyYellow;

  @override
  Color get blueButtonBackground => AppColors.skyBlue;

  @override
  Color get confirmText => AppColors.skyBlue;

  @override
  Color get focusedBorder => AppColors.skyBlue;

  @override
  Color get snackbarBgColor => AppColors.skyBlue;

  // All theme-aware getters use defaults from AbstractThemeColors (light palette)
}
