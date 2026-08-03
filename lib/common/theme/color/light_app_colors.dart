import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:flutter/material.dart';

class LightAppColors extends AbstractThemeColors {
  const LightAppColors();

  // WCAG AA 대비 보정을 위한 라이트 모드 전용 값 — 나머지 getter는 모두
  // AbstractThemeColors 기본값(라이트 팔레트)을 그대로 사용
  @override
  Color get iconButtonInactivate => AppColors.textMutedLight;

  @override
  Color get hintText => AppColors.textMutedLight;

  @override
  Color get textSecondary => AppColors.textMutedLight;

  @override
  Color get error => AppColors.errorRedLight;
}
