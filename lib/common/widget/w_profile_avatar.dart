import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/role_badge_style.dart';
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

  Widget _buildWithBadge(Widget avatar, RoleBadgeStyle style) {
    final badgeSize = radius * 0.8;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Tooltip(
            message: style.tooltip,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: style.color,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, size: badgeSize * 0.7, color: Colors.white),
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

    final style = roleBadgeStyleFor(userRole: userRole, certified: certified);
    if (style == null) return avatar;

    return _buildWithBadge(avatar, style);
  }
}
