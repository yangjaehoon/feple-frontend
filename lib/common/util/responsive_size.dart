import 'package:flutter/material.dart';

/// 화면 크기에 비례하는 반응형 유틸리티
///
/// 기준 디자인: 390 x 844 (iPhone 14 기준)
/// 사용법:
/// ```dart
/// final rs = ResponsiveSize(context);
/// Container(height: rs.h(60));  // 화면 높이의 비율로 계산
/// Padding(padding: rs.px(16));  // 화면 너비의 비율로 계산
/// Text('Hi', style: TextStyle(fontSize: rs.sp(14))); // 폰트 비율
/// ```
class ResponsiveSize {
  /// 기준 디자인 크기 (iPhone 14)
  static const double _designWidth = 390;
  static const double _designHeight = 844;

  final double screenWidth;
  final double screenHeight;

  ResponsiveSize(BuildContext context)
      : screenWidth = MediaQuery.of(context).size.width,
        screenHeight = MediaQuery.of(context).size.height;

  /// 너비 기반 비율 (패딩, 마진, 아이콘 크기 등)
  double w(double value) => value * screenWidth / _designWidth;

  /// 높이 기반 비율 (앱바, 카드, 간격 등)
  double h(double value) => value * screenHeight / _designHeight;

  /// 폰트 크기 비율 (너비 기반 — 줄당 글자 수 유지)
  double sp(double value) => value * screenWidth / _designWidth;

  /// 수평 패딩 EdgeInsets
  EdgeInsets px(double value) =>
      EdgeInsets.symmetric(horizontal: w(value));

  /// 수직 패딩 EdgeInsets
  EdgeInsets py(double value) =>
      EdgeInsets.symmetric(vertical: h(value));
}
