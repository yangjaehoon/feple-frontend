import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/bounded_responsive_size.dart';
import 'package:flutter/material.dart';

class ArtistCircleImage extends StatelessWidget {
  final String? imageUrl;
  final bool isFollowed;

  const ArtistCircleImage({
    super.key,
    required this.imageUrl,
    required this.isFollowed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // w_festival_artists.dart의 가로 스크롤 행에서 쓰이므로 boundedResponsiveSize로
    // 태블릿급 너비에서 항목이 과도하게 넓어지는 걸 막는다(위젯 테스트로 재현·확인).
    final screenWidth = boundedWidthBasis(context);
    if (!isFollowed) return _buildPlainImage(colors, screenWidth);
    return _buildFollowedImage(colors, screenWidth);
  }

  Widget _buildAvatarContent(AbstractThemeColors colors, double size) {
    Widget fallback(AbstractThemeColors c) => SizedBox.square(
          dimension: size,
          child: ColoredBox(
            color: c.activate.withValues(alpha: 0.08),
            child: Icon(Icons.person_rounded, color: c.activate, size: size * 0.46),
          ),
        );
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return SizedBox.square(
        dimension: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 112,
          fadeInDuration: AppDimens.animXFast,
          fadeOutDuration: AppDimens.animTapFeedback,
          placeholder: (_, _) => fallback(colors),
          errorWidget: (_, _, _) => fallback(colors),
        ),
      );
    }
    return fallback(colors);
  }

  Widget _buildPlainImage(AbstractThemeColors colors, double screenWidth) {
    final size = screenWidth * (56 / 390);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.activate.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: _buildAvatarContent(colors, size)),
    );
  }

  Widget _buildFollowedImage(AbstractThemeColors colors, double screenWidth) {
    final size = screenWidth * (56 / 390);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colors.activate, colors.activate.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.backgroundMain,
        ),
        padding: const EdgeInsets.all(1.5),
        child: ClipOval(child: _buildAvatarContent(colors, screenWidth * (48 / 390))),
      ),
    );
  }
}
