import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 앱 전역 입력 필드 반경(`AppDimens.cardRadiusTiny`)을 쓰는 공용 OutlineInputBorder.
OutlineInputBorder appInputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      borderSide: BorderSide(color: color, width: width),
    );

/// `AppTextField`/`NicknameField`가 공유하는 입력 필드 크롬(아이콘·hint·배경·테두리).
/// [borderColor]를 넘기지 않으면 기본(`colors.divider`) 테두리를 사용한다.
InputDecoration buildAppFieldDecoration({
  required AbstractThemeColors colors,
  required IconData icon,
  required String hintText,
  Color? borderColor,
  Widget? suffixIcon,
  String? counterText,
  TextStyle? counterStyle,
}) {
  return InputDecoration(
    counterText: counterText,
    counterStyle: counterStyle,
    prefixIcon: Icon(icon, color: colors.activate, size: 22),
    suffixIcon: suffixIcon,
    hintText: hintText,
    hintStyle: TextStyle(color: colors.hintText, fontSize: AppDimens.fontSizeLg),
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: appInputBorder(colors.divider),
    enabledBorder: appInputBorder(borderColor ?? colors.divider),
    focusedBorder: appInputBorder(colors.focusedBorder, width: 2),
  );
}
