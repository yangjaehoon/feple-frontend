import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 아이콘 + 텍스트 Row 구조의 PopupMenuItem을 생성하는 공통 빌더.
///
/// [danger]가 true이면 [AbstractThemeColors.error]를 사용한다.
/// [color]를 명시하면 [danger] 설정을 덮어쓴다.
PopupMenuItem<T> buildPopupMenuItem<T>({
  required T value,
  required IconData icon,
  required String label,
  required AbstractThemeColors colors,
  bool danger = false,
  Color? color,
  double height = 44,
  double iconSize = 16,
  double spacing = 10,
  double? fontSize,
  FontWeight? fontWeight,
}) {
  final effectiveColor =
      color ?? (danger ? colors.error : colors.textTitle);
  return PopupMenuItem<T>(
    value: value,
    height: height,
    child: Row(
      children: [
        Icon(icon, size: iconSize, color: effectiveColor),
        SizedBox(width: spacing),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
