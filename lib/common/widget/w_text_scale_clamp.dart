import 'package:flutter/material.dart';

/// WCAG 1.4.4: 텍스트 200%까지 확대 지원. 픽셀 고정 레이아웃(타임테이블 그리드)만
/// 별도로 자체 상한을 두어 대응 — TimetableGrid, TimetableFullscreenGrid 참고.
/// `MaterialApp.builder`에 그대로 전달해서 쓴다.
Widget clampTextScaleBuilder(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 2.0),
    ),
    child: child!,
  );
}
