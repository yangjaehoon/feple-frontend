import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:flutter/material.dart';

class HomeArtistsSection extends StatelessWidget {
  static const int maxPreview = 10;

  const HomeArtistsSection({
    super.key,
    required this.artists,
    required this.onTap,
    this.hasError = false,
    this.onRetry,
    this.onShowMore,
  });

  final List<FollowedArtist>? artists;
  final void Function(FollowedArtist) onTap;
  final bool hasError;
  final VoidCallback? onRetry;
  final VoidCallback? onShowMore;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: onRetry),
      );
    }

    if (artists == null) return _buildSkeleton();
    if (artists!.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'no_followed_artists'.tr(),
      );
    }
    final preview = artists!.take(maxPreview).toList();
    final remaining = artists!.length - maxPreview;
    final showMoreItem = remaining > 0 && onShowMore != null;
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: preview.length + (showMoreItem ? 1 : 0),
        itemBuilder: (_, index) {
          if (showMoreItem && index == preview.length) {
            return _ShowMoreItem(remaining: remaining, onTap: onShowMore!);
          }
          return _ArtistItem(
            key: ValueKey(preview[index].id),
            artist: preview[index],
            onTap: onTap,
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              SkeletonBox(
                width: 74,
                height: 74,
                borderRadius: BorderRadius.circular(37),
              ),
              const SizedBox(height: 6),
              const SkeletonBox(width: 56, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowMoreItem extends StatelessWidget {
  const _ShowMoreItem({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.activate.withValues(alpha: 0.1),
                border: Border.all(color: colors.activate.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+$remaining',
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeMd,
                      fontWeight: FontWeight.w700,
                      color: colors.activate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                'see_more'.tr(),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: colors.activate,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistItem extends StatelessWidget {
  const _ArtistItem({super.key, required this.artist, required this.onTap});

  final FollowedArtist artist;
  final void Function(FollowedArtist) onTap;

  String _displayName(BuildContext context) =>
      artist.displayName(context.isEnglish);

  Widget _buildAvatar(AbstractThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.followRingColor,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        child: CircleAvatar(
          radius: 32,
          backgroundColor: colors.backgroundMain,
          backgroundImage: (artist.profileImageUrl != null &&
                  artist.profileImageUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(artist.profileImageUrl!, maxWidth: 150)
              : null,
          child: (artist.profileImageUrl == null || artist.profileImageUrl!.isEmpty)
              ? Icon(Icons.person_rounded, size: 28, color: colors.textSecondary)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TapScale(
      onTap: () => onTap(artist),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            _buildAvatar(colors),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                _displayName(context),
                style: TextStyle(fontSize: AppDimens.fontSizeXs, fontWeight: FontWeight.w600, color: colors.textTitle),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
