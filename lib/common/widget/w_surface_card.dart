import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 카드 형태의 공통 컨테이너.
/// margin·borderRadius·shadow를 한 곳에서 관리해 DRY 위반을 방지한다.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double shadowAlpha;
  final double? width;
  final bool clipContent;

  const SurfaceCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppDimens.paddingHorizontal,
      vertical: AppDimens.paddingVertical,
    ),
    this.borderRadius = AppDimens.cardRadius,
    this.shadowAlpha = 0.12,
    this.width,
    this.clipContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(borderRadius);
    final content =
        clipContent ? ClipRRect(borderRadius: radius, child: child) : child;
    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: shadowAlpha),
            blurRadius: borderRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}
