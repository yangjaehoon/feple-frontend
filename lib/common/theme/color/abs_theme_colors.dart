import 'package:feple/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

export 'package:feple/common/constant/app_colors.dart';

typedef ColorProvider = Color Function();

abstract class AbstractThemeColors {
  const AbstractThemeColors();

  Color get drawerBg => AppColors.surfaceWhite;

  Color get iconButton => AppColors.skyBlue;

  Color get iconButtonInactivate => AppColors.textMuted;

  Color get inActivate => const Color.fromARGB(255, 200, 207, 220);

  Color get activate => AppColors.skyBlue;

  Color get badgeBg => AppColors.sunnyYellow;

  Color get badgeBorder => Colors.transparent;

  Color get divider => const Color.fromARGB(255, 238, 238, 238);

  Color get text => AppColors.textMain;

  Color get hintText => AppColors.textMuted;

  Color get focusedBorder => AppColors.skyBlue;

  Color get confirmText => AppColors.skyBlue;

  Color get snackbarBgColor => AppColors.skyBlue;

  Color get appBarBackground => AppColors.skyBlue;

  // === Theme-aware UI colors ===

  /// Main screen / fragment background
  Color get backgroundMain => AppColors.backgroundLight;

  /// Card/surface background
  Color get surface => AppColors.surfaceWhite;

  /// App bar solid color (no gradient)
  Color get appBarColor => AppColors.skyBlue;

  /// Bottom nav background
  Color get bottomNavBg => AppColors.surfaceWhite;

  /// Bottom nav shadow color
  Color get bottomNavShadow => Colors.black;

  /// Primary text color (titles, etc.)
  Color get textTitle => AppColors.textMain;

  /// Secondary/muted text color
  Color get textSecondary => AppColors.textMuted;

  /// Community board header colors (solid, no gradient)
  Color get hotBoardHeader => AppColors.skyBlue;
  Color get freeBoardHeader => AppColors.skyBlue;
  Color get getUserBoardHeader => AppColors.skyBlue;

  /// Soft shadow color
  Color get cardShadow => Colors.black;

  /// Loading indicator color
  Color get loadingIndicator => AppColors.skyBlue;

  /// Divider for list items
  Color get listDivider => const Color(0xFFF0F0F0);

  /// Stat card background
  Color get statCardBg => AppColors.surfaceWhite;

  /// Profile ring color (solid)
  Color get profileRingColor => AppColors.skyBlue;

  /// Certification ring color (solid)
  Color get certRingColor => AppColors.skyBlue;

  /// Follow artist ring color (solid)
  Color get followRingColor => AppColors.skyBlue;

  /// Section title bar color
  Color get sectionBarColor => AppColors.skyBlue;

  /// Swiper overlay color
  Color get swiperOverlay => Colors.black;

  /// Level badge colors
  Color get levelBadgeBg => AppColors.skyBlue;
  Color get levelBadgeText => Colors.white;

  /// Action button primary color (solid, no gradient)
  Color get actionBtnPrimary => AppColors.skyBlue;

  /// Action button secondary background / border
  Color get actionBtnSecondaryBg => AppColors.surfaceWhite;
  Color get actionBtnSecondaryBorder => const Color(0xFFE2E8F0);

  /// Drawer header color
  Color get drawerHeaderBg => AppColors.skyBlue;

  /// Sub/accent color
  Color get accentColor => AppColors.sunnyYellow;

  /// Festival "ongoing" status badge background
  Color get statusOngoingColor => const Color(0xFF43A047);

  /// Like button active color (heart icon)
  Color get likeActiveColor => AppColors.kawaiiPink;

  /// Error / destructive color
  Color get error => AppColors.errorRed;
}
