import 'package:flutter/material.dart';

/// [ResponsiveSize]와 같은 390px 기준 스케일이되, 화면 폭 자체를 [maxWidthBasis]
/// (기본 480px, 큰 폰 상한)로 클램프한다.
///
/// 스크롤되지 않는 Column 기반 목록(SkeletonRowList 등)이나, 가로 스크롤 목록에서
/// 항목이 과도하게 넓어져 뒤쪽 항목이 초기 뷰포트 밖으로 밀려나는 곳처럼, 태블릿급
/// 너비에서 그대로 비례시키면 실제로 넘치거나 항목이 안 보이는 문제가 위젯 테스트로
/// 재현된 자리에만 쓴다. 일반적인 반응형 크기는 `ResponsiveSize`를 그대로 쓸 것.
double boundedResponsiveSize(
  BuildContext context,
  double baseSize, {
  double baseWidth = 390,
  double maxWidthBasis = 480,
}) {
  return boundedWidthBasis(context, max: maxWidthBasis) * (baseSize / baseWidth);
}

/// 화면 폭 자체를 여러 크기 계산에 재사용해야 할 때 쓰는, 상한 클램프된 화면 폭.
double boundedWidthBasis(BuildContext context, {double max = 480}) {
  final width = MediaQuery.sizeOf(context).width;
  return width < max ? width : max;
}
