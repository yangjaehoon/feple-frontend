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

    final image = Container(
      width: 52,
      height: 52,
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
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(
                  Icons.person_rounded,
                  color: colors.activate.withValues(alpha: 0.5),
                  size: 26,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: colors.activate.withValues(alpha: 0.5),
                size: 26,
              ),
      ),
    );

    if (!isFollowed) return image;

    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.skyBlue, AppColors.skyBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(1.5),
        child: ClipOval(
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: 52,
                  height: 52,
                  errorWidget: (context, url, error) => Icon(
                    Icons.person_rounded,
                    color: colors.activate.withValues(alpha: 0.5),
                    size: 26,
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: colors.activate.withValues(alpha: 0.5),
                  size: 26,
                ),
        ),
      ),
    );
  }
}
