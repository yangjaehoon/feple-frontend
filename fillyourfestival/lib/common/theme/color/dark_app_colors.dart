import 'package:fast_app_base/common/theme/color/abs_theme_colors.dart';
import 'package:flutter/material.dart';

/// Dark Kawaii Theme — solid colors, no gradients
class DarkAppColors extends AbstractThemeColors {
  const DarkAppColors();

  static const Color _darkBg = Color(0xFF111C21);
  static const Color _darkSurface = Color(0xFF1A2C38);
  static const Color _darkCard = Color(0xFF243442);
  static const Color _darkTextPrimary = Color(0xFFE8EDF2);
  static const Color _darkTextSecondary = Color(0xFF8CA0B3);
  static const Color _darkDivider = Color(0xFF2E4050);

  @override
  Color get seedColor => AppColors.skyBlue;

  @override
  Color get activate => AppColors.skyBlue;

  @override
  Color get badgeBg => AppColors.sunnyYellow;

  @override
  Color get divider => _darkDivider;

  @override
  Color get drawerBg => _darkSurface;

  @override
  Color get hintText => _darkTextSecondary;

  @override
  Color get iconButton => AppColors.skyBlue;

  @override
  Color get iconButtonInactivate => _darkTextSecondary;

  @override
  Color get inActivate => const Color(0xFF2E4050);

  @override
  Color get text => _darkTextPrimary;

  @override
  Color get focusedBorder => AppColors.skyBlue;

  @override
  Color get confirmText => AppColors.skyBlue;

  @override
  Color get blueButtonBackground => AppColors.skyBlue;

  @override
  Color get drawerText => _darkTextPrimary;

  @override
  Color get snackbarBgColor => AppColors.skyBlue;

  @override
  Color get appBarBackground => _darkSurface;

  // === Dark overrides ===

  @override
  Color get backgroundMain => _darkBg;

  @override
  Color get surface => _darkSurface;

  @override
  Color get appBarColor => _darkSurface;

  @override
  Color get bottomNavBg => _darkSurface;

  @override
  Color get bottomNavShadow => Colors.black;

  @override
  Color get textTitle => _darkTextPrimary;

  @override
  Color get textSecondary => _darkTextSecondary;

  @override
  Color get hotBoardHeader => _darkCard;
  @override
  Color get freeBoardHeader => _darkCard;
  @override
  Color get getUserBoardHeader => _darkCard;

  @override
  Color get cardShadow => Colors.black;

  @override
  Color get loadingIndicator => AppColors.skyBlue;

  @override
  Color get listDivider => _darkDivider;

  @override
  Color get statCardBg => _darkCard;

  @override
  Color get profileRingColor => AppColors.skyBlue;

  @override
  Color get certRingColor => AppColors.skyBlue;

  @override
  Color get followRingColor => AppColors.skyBlue;

  @override
  Color get sectionBarColor => AppColors.skyBlue;

  @override
  Color get swiperOverlay => _darkSurface;

  @override
  Color get levelBadgeBg => AppColors.skyBlue;
  @override
  Color get levelBadgeText => AppColors.skyBlue;

  @override
  Color get actionBtnPrimary => AppColors.skyBlue;

  @override
  Color get actionBtnSecondaryBg => _darkCard;
  @override
  Color get actionBtnSecondaryBorder => _darkDivider;

  @override
  Color get drawerHeaderBg => _darkSurface;

  @override
  Color get accentColor => AppColors.sunnyYellow;

  @override
  Color get scrollableItem => _darkTextPrimary;
}
