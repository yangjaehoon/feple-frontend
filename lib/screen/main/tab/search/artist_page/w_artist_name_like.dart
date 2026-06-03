import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_festival_calendar.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import '../../../../../common/app_events.dart';
import 'image_collection/f_image_collection.dart';

class ArtistNameLike extends StatefulWidget {
  const ArtistNameLike({
    super.key,
    required this.artistName,
    required this.artistId,
    this.initialFollowerCount,
  });

  final String artistName;
  final int artistId;
  final int? initialFollowerCount;

  @override
  State<ArtistNameLike> createState() => _ArtistNameLikeState();
}

class _ArtistNameLikeState extends State<ArtistNameLike>
    with SingleTickerProviderStateMixin {
  late final ArtistFollowNotifier _followNotifier;
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _followNotifier = ArtistFollowNotifier(
      artistId: widget.artistId,
      initialFollowerCount: widget.initialFollowerCount ?? 0,
    )..addListener(() { if (mounted) setState(() {}); })
     ..init();
    _heartController = AnimationController(
      vsync: this,
      duration: AppDimens.animNormal,
      lowerBound: 1.0,
      upperBound: 1.3,
    );
  }

  @override
  void dispose() {
    _followNotifier.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow() async {
    _heartController.forward().whenComplete(_heartController.reverse);
    try {
      await _followNotifier.toggle();
      if (!mounted) return;
      AppEvents.artistFollowChanged.value++;
      context.showSuccessSnackbar(
        _followNotifier.isFollowed ? 'follow_done'.tr() : 'follow_cancel'.tr(),
      );
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackbar('follow_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Artist name + follower count ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.artistName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 6,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Follow button + follower count + action icons ──
            Row(
              children: [
                // Follow button
                _buildFollowButton(
                  isFollowed: _followNotifier.isFollowed,
                  isLoading: _followNotifier.isLoading,
                ),

                const SizedBox(width: 12),

                // Follower count with heart icon
                ScaleTransition(
                  scale: _heartController,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.kawaiiPink,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: AppDimens.animNormal,
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    _formatCount(_followNotifier.followCount),
                    key: ValueKey(_followNotifier.followCount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),

                const Spacer(),

                // Action icons
                _buildActionIcon(
                  icon: Icons.calendar_month_rounded,
                  label: 'action_schedule'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      SlideRoute(
                        builder: (context) => const FtvCalender(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                _buildActionIcon(
                  icon: Icons.photo_library_rounded,
                  label: 'action_gallery'.tr(),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      SlideRoute(
                        builder: (context) => ImgCollection(
                          artistName: widget.artistName,
                          artistId: widget.artistId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pill-shaped follow/following button with gradient
  Widget _buildFollowButton({required bool isFollowed, required bool isLoading}) {
    return GestureDetector(
      onTap: isLoading ? null : _toggleFollow,
      child: AnimatedContainer(
        duration: AppDimens.animNormal,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: isFollowed
              ? null
              : const LinearGradient(
                  colors: [AppColors.skyBlue, AppColors.skyBlueLight],
                ),
          color: isFollowed ? Colors.white.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: isFollowed
              ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(
                      isFollowed ? Icons.check_rounded : Icons.favorite_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
              const SizedBox(width: 6),
              Opacity(
                opacity: isLoading ? 0 : 1,
                child: Text(
                  isFollowed ? 'following'.tr() : 'follow'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  /// Glassmorphic circular action icon button
  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}만';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}천';
    }
    return count.toString();
  }
}
