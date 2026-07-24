import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

class ArtistCard extends StatelessWidget {
  final String? profileImageUrl;
  final String name;
  final bool isFollowed;

  const ArtistCard({
    super.key,
    required this.profileImageUrl,
    required this.name,
    required this.isFollowed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
              boxShadow: [
                BoxShadow(
                  color: isFollowed
                      ? colors.activate.withValues(alpha: 0.35)
                      : colors.cardShadow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            foregroundDecoration: isFollowed
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                    border: Border.all(color: colors.activate, width: 2.5),
                  )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
              child: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: profileImageUrl!,
                      memCacheWidth: 200,
                      fit: BoxFit.cover,
                      fadeInDuration: AppDimens.animXFast,
                      fadeOutDuration: AppDimens.animTapFeedback,
                      placeholder: (_, _) => const SkeletonBox(height: double.infinity),
                      errorWidget: (_, _, _) => _buildPlaceholder(colors),
                    )
                  : _buildPlaceholder(colors),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            fontWeight: isFollowed ? FontWeight.w700 : FontWeight.w600,
            color: isFollowed ? colors.activate : colors.textTitle,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPlaceholder(AbstractThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.activate.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      ),
      child: Icon(Icons.person_rounded, color: colors.activate, size: 40),
    );
  }
}
