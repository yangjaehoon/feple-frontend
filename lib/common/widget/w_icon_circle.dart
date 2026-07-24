import 'package:feple/common/common.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:flutter/material.dart';

/// 로그인/인증 플로우에서 반복되는, 화면 너비 비율 기반 원형 아이콘 배지.
class IconCircle extends StatelessWidget {
  final IconData icon;

  /// 기준 디자인(390dp 너비)에서의 원 지름
  final double sizeAt390;

  const IconCircle({super.key, required this.icon, this.sizeAt390 = 88});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = ResponsiveSize(context).w(sizeAt390);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.activate.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.5, color: colors.activate),
    );
  }
}
