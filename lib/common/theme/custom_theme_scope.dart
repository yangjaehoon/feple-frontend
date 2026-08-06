import 'package:flutter/material.dart';

import '../data/preference/prefs.dart';
import 'custom_theme.dart';
import 'custom_theme_holder.dart';
import 'theme_util.dart';

class CustomThemeScope extends StatefulWidget {
  final Widget child;

  const CustomThemeScope({super.key, required this.child});

  @override
  State<CustomThemeScope> createState() => _CustomThemeScopeState();
}

class _CustomThemeScopeState extends State<CustomThemeScope> {
  late CustomTheme theme = savedTheme ?? systemTheme;

  void handleChangeTheme(CustomTheme theme) {
    setState(() => this.theme = theme);
  }

  @override
  Widget build(BuildContext context) {
    return CustomThemeHolder(
      changeTheme: handleChangeTheme,
      theme: theme,
      child: widget.child,
    );
  }

  CustomTheme? get savedTheme => Prefs.appTheme.get();

  CustomTheme get systemTheme {
    switch (ThemeUtil.systemBrightness) {
      case Brightness.dark:
        return CustomTheme.dark;
      case Brightness.light:
        return CustomTheme.light;
    }
  }
}
