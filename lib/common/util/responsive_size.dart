import 'package:flutter/material.dart';

/// 화면 크기에 비례하는 반응형 유틸리티
///
/// 기준 디자인: 390 x 844 (iPhone 14 기준)
///
/// 펼친 폴더블 등 태블릿급 화면에서는 계산에 쓰는 화면 크기 자체를
/// [_maxWidthBasis]×[_maxHeightBasis](가장 큰 폰 기준, 480×~1038)로 클램프한다 —
/// 그 이상 커지면 패딩·폰트·카드가 디자인 의도보다 비례 이상으로 확대되는
/// 문제가 있었다(갤럭시 Z Fold 실측으로 확인). 두 상한의 비율을 기준 디자인과
/// 동일하게 맞춰 가로/세로 스케일이 서로 다른 배율로 벌어지지 않게 한다.
///
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

  static const double _maxWidthBasis = 480;
  static const double _maxHeightBasis = _maxWidthBasis * _designHeight / _designWidth;

  final double screenWidth;
  final double screenHeight;

  ResponsiveSize(BuildContext context)
      : screenWidth = _clampBasis(MediaQuery.sizeOf(context).width, _maxWidthBasis),
        screenHeight = _clampBasis(MediaQuery.sizeOf(context).height, _maxHeightBasis);

  static double _clampBasis(double value, double max) => value < max ? value : max;

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
