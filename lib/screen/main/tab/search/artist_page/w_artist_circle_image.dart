import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
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
    if (!isFollowed) return _buildPlainImage(colors);
    return _buildFollowedImage(colors);
  }

  Widget _buildAvatarContent(AbstractThemeColors colors, double size) {
    final icon = Icon(
      Icons.person_rounded,
      color: colors.activate.withValues(alpha: 0.5),
      size: 26,
    );
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        memCacheWidth: 110,
        errorWidget: (context, url, error) => icon,
      );
    }
    return icon;
  }

  Widget _buildPlainImage(AbstractThemeColors colors) {
    return Container(
      width: 56,
      height: 56,
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
      child: ClipOval(child: _buildAvatarContent(colors, 56)),
    );
  }

  Widget _buildFollowedImage(AbstractThemeColors colors) {
    return Container(
      width: 56,
      height: 56,
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
        child: ClipOval(child: _buildAvatarContent(colors, 48)),
      ),
    );
  }
}
