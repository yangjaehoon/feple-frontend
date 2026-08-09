import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 프로필 관련 화면(내 프로필/다른 유저 프로필/프로필 편집)에서 반복되던
/// "링(그림자) + 안쪽 원 배경" 프레임을 공용화. 아바타 내용(이미지 소스/폴백)은
/// 화면마다 다르므로 [child]로 받는다.
class ProfileAvatarRing extends StatelessWidget {
  final double size;
  final Widget child;

  const ProfileAvatarRing({super.key, required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.profileRingColor,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        child: child,
      ),
    );
  }
}
