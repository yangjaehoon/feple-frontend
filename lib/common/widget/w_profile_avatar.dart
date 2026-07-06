import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/user_roles.dart';
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

  Widget _buildAvatar(BuildContext context, AbstractThemeColors colors) {
    if (anonymous) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colors.listDivider,
        backgroundImage: const AssetImage('assets/image/feple_logo.png'),
      );
    }
    if (_hasCustomImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(
          imageUrl!,
          // radius*2=diameter, *2=Retina — 기본값 없으면 원본 해상도로 메모리 로드
          maxWidth: (radius * 4).round(),
        ),
        backgroundColor: colors.activate,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.activate,
      child: Text(
        nickname.isNotEmpty ? nickname[0] : '?',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildWithBadge(Widget avatar) {
    final isAdmin = userRole == kRoleAdmin;
    final isArtist = userRole == kRoleArtist;

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
      // artist 배지와 아이콘이 같으면 색약 사용자가 색상만으로 구분해야 함 — 아이콘도 다르게
      badgeIcon = Icons.local_activity_rounded;
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
    final avatar = _buildAvatar(context, colors);

    final isAdmin = userRole == kRoleAdmin;
    final isArtist = userRole == kRoleArtist;
    final hasBadge = certified || isAdmin || isArtist;
    if (!hasBadge) return avatar;

    return _buildWithBadge(avatar);
  }
}
