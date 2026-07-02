import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/theme/color/dark_app_colors.dart';
import 'package:feple/common/theme/color/light_app_colors.dart';
import 'package:feple/common/theme/shadows/dark_app_shadows.dart';
import 'package:feple/common/theme/shadows/light_app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

enum CustomTheme {
  dark(
    DarkAppColors(),
    DarkAppShadows(),
  ),
  light(
    LightAppColors(),
    LightAppShadows(),
  );

  const CustomTheme(this.appColors, this.appShadows);

  final AbstractThemeColors appColors;
  final AbsThemeShadows appShadows;

  ThemeData get themeData {
    switch (this) {
      case CustomTheme.dark:
        return darkTheme;
      case CustomTheme.light:
        return lightTheme;
    }
  }

  Brightness get brightness => themeData.brightness;
}

// M3 Type Scale — Pretendard 폰트 기준
// 색상은 ColorScheme에서 자동 적용되므로 size/weight/tracking만 정의
const _m3TextTheme = TextTheme(
  displayLarge:   TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
  displayMedium:  TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0),
  displaySmall:   TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0),
  headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.25),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0),
  headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0),
  titleLarge:     TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0),
  titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
  titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
  bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
  bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
  bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
  labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
  labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
);

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Pretendard',
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.backgroundLight,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.skyBlue,
    brightness: Brightness.light,
  ),
  textTheme: _m3TextTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 2, // M3 스크롤 시 레이어 구분
    foregroundColor: AppColors.textMain,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
    titleTextStyle: TextStyle(
      fontSize: AppDimens.fontSizeTitle,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.textMain,
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surfaceWhite,
    elevation: 0,
    // M3 SecondaryContainer Tone 90 계열 — 명확한 선택 표시
    indicatorColor: const Color(0xFFCCE9F8),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.skyBlueDark);
      }
      return const IconThemeData(color: AppColors.textMuted);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontSize: 12, // M3 Label Medium
          fontWeight: FontWeight.w700,
          color: AppColors.skyBlueDark,
        );
      }
      return const TextStyle(
        fontSize: 12, // M3 Label Medium
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: Color(0xFFDDE3E7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: Color(0xFFDDE3E7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: AppColors.skyBlueDark, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
    ),
    filled: true,
    fillColor: AppColors.surfaceWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(color: AppColors.textMuted),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.skyBlueDark, // 대비비 ≥ 4.5:1
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.shapeButton),
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.skyBlueDark,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.shapeButton),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceWhite,
    elevation: 1, // M3 Elevated Card — Surface Tint으로 레이어 구분
    surfaceTintColor: AppColors.skyBlue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
    ),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeDialog),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFEDF0F2),
    thickness: 1,
    space: 1,
  ),
  chipTheme: const ChipThemeData(
    shape: StadiumBorder(), // M3 Chip = Full shape
  ),
);

const _darkBg = Color(0xFF111C21);
const _darkSurface = Color(0xFF1A2C38);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Pretendard',
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _darkBg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.skyBlue,
    brightness: Brightness.dark,
  ),
  textTheme: _m3TextTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 2,
    foregroundColor: Color(0xFFE8EDF2),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
    titleTextStyle: TextStyle(
      fontSize: AppDimens.fontSizeTitle,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: Color(0xFFE8EDF2),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _darkSurface,
    elevation: 0,
    // M3 다크 모드 indicator — PrimaryContainer Tone 30 계열
    indicatorColor: const Color(0xFF004D6B),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.skyBlueLight);
      }
      return const IconThemeData(color: Color(0xFF8CA0B3));
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.skyBlueLight,
        );
      }
      return const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8CA0B3),
      );
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: Color(0xFF2A3F50)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: Color(0xFF2A3F50)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: AppColors.skyBlueLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeInput),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
    ),
    filled: true,
    fillColor: _darkSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(color: Color(0xFF8CA0B3)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.skyBlueDark,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.shapeButton),
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.skyBlueDark,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.shapeButton),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  cardTheme: CardThemeData(
    color: _darkSurface,
    elevation: 1,
    surfaceTintColor: AppColors.skyBlue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
    ),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.shapeDialog),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF1E3345),
    thickness: 1,
    space: 1,
  ),
  chipTheme: const ChipThemeData(
    shape: StadiumBorder(),
  ),
);
