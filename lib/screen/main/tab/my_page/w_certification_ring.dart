import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:flutter/material.dart';

/// 인증 카드 그리드(내 프로필/다른 유저 프로필/축제 인증 목록)에서 반복되던
/// 상태색 링 + 포스터 썸네일 프레임을 공용화.
class CertificationRing extends StatelessWidget {
  final String? imageUrl;
  final Color ringColor;
  final double ringAlpha;

  /// CircleAvatar 위에 표시할 위젯(로딩 인디케이터 등). null이면 imageUrl 유무에
  /// 따라 기본 아이콘/없음으로 표시한다.
  final Widget? overlay;

  const CertificationRing({
    super.key,
    required this.imageUrl,
    required this.ringColor,
    this.ringAlpha = 0.6,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: ringAlpha),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        child: CircleAvatar(
          radius: ResponsiveSize(context).w(44),
          backgroundColor: ringColor.withValues(alpha: 0.15),
          backgroundImage: imageUrl != null
              ? CachedNetworkImageProvider(imageUrl!, maxWidth: 132)
              : null,
          child: overlay ??
              (imageUrl == null
                  ? Icon(Icons.photo_rounded, size: 26, color: colors.textTitle.withValues(alpha: 0.3))
                  : null),
        ),
      ),
    );
  }
}
