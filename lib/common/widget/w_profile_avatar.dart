import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 프로필 이미지 + 역할 배지(Admin/Artist/인증) 오버레이 위젯.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String nickname;
  final bool certified;
  final String? userRole;
  final double radius;
  final bool anonymous;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.nickname,
    this.certified = false,
    this.userRole,
    this.radius = 20,
    this.anonymous = false,
  });

  bool get _hasCustomImage {
    final url = imageUrl;
    return url != null && !url.contains('feple_logo');
  }

  Widget _buildAvatar(AbstractThemeColors colors) {
    if (anonymous) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Padding(
          padding: EdgeInsets.all(radius * 0.22),
          child: Image.asset('assets/image/feple_logo.png'),
        ),
      );
    }
    if (_hasCustomImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
        backgroundColor: colors.activate,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.activate,
      child: Text(
        nickname.isNotEmpty ? nickname[0] : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildWithBadge(Widget avatar) {
    final isAdmin = userRole == 'ADMIN';
    final isArtist = userRole == 'ARTIST';

    final Color badgeColor;
    final IconData badgeIcon;
    final String badgeTooltip;
    if (isAdmin) {
      badgeColor = AppColors.badgeAdmin;
      badgeIcon = Icons.shield_rounded;
      badgeTooltip = 'badge_admin'.tr();
    } else if (isArtist) {
      badgeColor = AppColors.badgeArtist;
      badgeIcon = Icons.verified_rounded;
      badgeTooltip = 'badge_artist_certified'.tr();
    } else {
      badgeColor = AppColors.badgeCertified;
      badgeIcon = Icons.verified_rounded;
      badgeTooltip = 'badge_festival_certified'.tr();
    }

    final badgeSize = radius * 0.8;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Tooltip(
            message: badgeTooltip,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, size: badgeSize * 0.7, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final avatar = _buildAvatar(colors);

    final isAdmin = userRole == 'ADMIN';
    final isArtist = userRole == 'ARTIST';
    final hasBadge = certified || isAdmin || isArtist;
    if (!hasBadge) return avatar;

    return _buildWithBadge(avatar);
  }
}
