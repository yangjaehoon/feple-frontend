import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/festival_model.dart';
import 'package:flutter/material.dart';

class HomeFestivalsSection extends StatelessWidget {
  const HomeFestivalsSection({
    super.key,
    required this.festivals,
    required this.onTap,
    this.hasError = false,
    this.onRetry,
  });

  final List<FestivalModel>? festivals;
  final void Function(FestivalModel) onTap;
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

    if (festivals == null) {
      return SizedBox(
        height: 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SkeletonBox(
              width: 130,
              height: 190,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
    if (festivals!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text('no_liked_festivals'.tr(),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: festivals!.length,
        itemBuilder: (_, index) => _FestivalItem(
          key: ValueKey(festivals![index].id),
          festival: festivals![index],
          onTap: onTap,
        ),
      ),
    );
  }
}

class _FestivalItem extends StatelessWidget {
  const _FestivalItem({super.key, required this.festival, required this.onTap});

  final FestivalModel festival;
  final void Function(FestivalModel) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => onTap(festival),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(colors),
              _buildTitleOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(AbstractThemeColors colors) {
    return CachedNetworkImage(
      imageUrl: festival.posterUrl,
      memCacheWidth: 260,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: colors.surface,
        child: Icon(Icons.image_not_supported_rounded, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildTitleOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Text(
              festival.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
