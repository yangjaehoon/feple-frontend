import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/screen/main/tab/home/artist_page/w_ftv_calender.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../../api/artist_follow_api.dart';
import '../../../../../api/follow_response.dart';
import 'img_collection/f_img_collection.dart';

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
  final _followApi = ArtistFollowApi();

  bool isFollowed = false;
  int followCount = 0;
  bool isLoading = false;
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    followCount = widget.initialFollowerCount ?? 0;
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1.0,
      upperBound: 1.3,
    );
    _initFollowState();
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _initFollowState() async {
    try {
      final status = await _followApi.getFollowStatus(widget.artistId);
      if (!mounted) return;
      setState(() {
        isFollowed = status.followed;
        followCount = status.followerCount;
      });
    } catch (e) {
      // silently fail
    }
  }

  Future<void> toggleFollow() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    // Play heart bounce animation
    _heartController.forward().then((_) => _heartController.reverse());

    try {
      final FollowResponse res = isFollowed
          ? await _followApi.unfollow(widget.artistId)
          : await _followApi.follow(widget.artistId);

      if (!mounted) return;
      setState(() {
        isFollowed = res.followed;
        followCount = res.followerCount;
      });

      Fluttertoast.showToast(
        msg: isFollowed ? '💖 팔로우 완료' : '팔로우 취소',
        gravity: ToastGravity.BOTTOM,
        backgroundColor:
            isFollowed ? AppColors.skyBlue : AppColors.skyBlue,
        textColor: Colors.white,
        fontSize: 14,
      );
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '팔로우 처리 실패',
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
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
              Colors.black.withOpacity(0.65),
              Colors.black.withOpacity(0.0),
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
                _buildFollowButton(),

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
                Text(
                  _formatCount(followCount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),

                const Spacer(),

                // Action icons
                _buildActionIcon(
                  icon: Icons.textsms_rounded,
                  label: '채팅',
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                _buildActionIcon(
                  icon: Icons.calendar_month_rounded,
                  label: '일정',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FtvCalender(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                _buildActionIcon(
                  icon: Icons.photo_library_rounded,
                  label: '갤러리',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
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
  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: isLoading ? null : toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: isFollowed
              ? null
              : const LinearGradient(
                  colors: [AppColors.skyBlue, AppColors.skyBlueLight],
                ),
          color: isFollowed ? Colors.white.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(24),
          border: isFollowed
              ? Border.all(color: Colors.white.withOpacity(0.4), width: 1)
              : null,
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowed
                        ? Icons.check_rounded
                        : Icons.favorite_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFollowed ? '팔로잉' : '팔로우',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
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
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
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
