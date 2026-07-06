import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:flutter/material.dart';

import '../../common.dart';

extension ContextExtension on BuildContext {
  AbstractThemeColors get appColors => CustomThemeHolder.of(this).appColors;

  AbsThemeShadows get appShadows => CustomThemeHolder.of(this).appShadows;

  CustomTheme get themeType => CustomThemeHolder.of(this).theme;

  Function(CustomTheme) get changeTheme => CustomThemeHolder.of(this).changeTheme;

  bool get isEnglish => locale.languageCode == 'en';
}
