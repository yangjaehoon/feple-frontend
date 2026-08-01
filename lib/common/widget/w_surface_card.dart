import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 화면마다 제각각이던 카드 그림자(blurRadius·alpha·offset)를 3단계로 통일한 프리셋.
/// SurfaceCard로 감쌀 수 없는 커스텀 Container(onTap·border 등이 필요한 경우)에서
/// `boxShadow: CardShadows.medium(colors)` 형태로 직접 사용한다.
class CardShadows {
  CardShadows._();

  static List<BoxShadow> subtle(AbstractThemeColors colors) => [
        BoxShadow(
          color: colors.cardShadow.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> medium(AbstractThemeColors colors) => [
        BoxShadow(
          color: colors.cardShadow.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> elevated(AbstractThemeColors colors) => [
        BoxShadow(
          color: colors.cardShadow.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

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
