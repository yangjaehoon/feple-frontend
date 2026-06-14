import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:flutter/material.dart';

class HomeArtistsSection extends StatelessWidget {
  const HomeArtistsSection({
    super.key,
    required this.artists,
    required this.onTap,
    this.hasError = false,
    this.onRetry,
  });

  final List<FollowedArtist>? artists;
  final void Function(FollowedArtist) onTap;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: onRetry),
      );
    }

    if (artists == null) return _buildSkeleton();
    if (artists!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text('no_followed_artists'.tr(),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists!.length,
        itemBuilder: (_, index) => _ArtistItem(
          key: ValueKey(artists![index].id),
          artist: artists![index],
          onTap: onTap,
        ),
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

class _ArtistItem extends StatelessWidget {
  const _ArtistItem({super.key, required this.artist, required this.onTap});

  final FollowedArtist artist;
  final void Function(FollowedArtist) onTap;

  String _displayName(BuildContext context) =>
      artist.displayName(context.locale.languageCode == 'en');

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
                style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: colors.textTitle),
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
