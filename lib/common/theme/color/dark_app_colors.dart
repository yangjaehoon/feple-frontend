import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:flutter/material.dart';

/// Dark Kawaii Theme — solid colors, no gradients
class DarkAppColors extends AbstractThemeColors {
  const DarkAppColors();

  /// custom_theme.dart의 ThemeData가 동일한 색을 다시 정의하지 않고
  /// 여기서 참조하도록 공개 상수로 노출.
  static const Color darkBackground = Color(0xFF111C21);
  static const Color darkSurface = Color(0xFF1A2C38);
  static const Color _darkCard = Color(0xFF243442);
  static const Color _darkTextPrimary = Color(0xFFE8EDF2);
  static const Color _darkTextSecondary = Color(0xFF8CA0B3);
  static const Color _darkDivider = Color(0xFF2E4050);

  @override
  Color get divider => _darkDivider;

  @override
  Color get drawerBg => darkSurface;

  @override
  Color get hintText => _darkTextSecondary;

  @override
  Color get iconButtonInactivate => _darkTextSecondary;

  @override
  Color get inActivate => _darkDivider;

  @override
  Color get text => _darkTextPrimary;

  @override
  Color get appBarBackground => darkSurface;

  // === Dark overrides ===

  @override
  Color get backgroundMain => darkBackground;

  @override
  Color get surface => darkSurface;

  @override
  Color get appBarColor => darkSurface;

  @override
  Color get appBarIconColor => _darkTextPrimary;

  @override
  Color get bottomNavBg => darkSurface;

  @override
  Color get textTitle => _darkTextPrimary;

  @override
  Color get textSecondary => _darkTextSecondary;

  @override
  Color get listDivider => _darkDivider;

  @override
  Color get statCardBg => _darkCard;

  @override
  Color get swiperOverlay => darkSurface;

  @override
  Color get actionBtnSecondaryBg => _darkCard;
  @override
  Color get actionBtnSecondaryBorder => _darkDivider;

  @override
  Color get drawerHeaderBg => darkSurface;

  // bottomNavShadow, cardShadow, loadingIndicator, profileRingColor,
  // certRingColor, followRingColor, sectionBarColor, levelBadgeBg/Text,
  // actionBtnPrimary, accentColor는 AbstractThemeColors 기본값과 동일해
  // 다크 테마 전용 override가 필요 없음
}
