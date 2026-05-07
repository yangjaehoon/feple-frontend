import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 닉네임 옆에 인라인으로 표시하는 역할 배지 아이콘.
///
/// 배지가 없는 경우 빈 위젯을 반환한다.
class InlineBadge extends StatelessWidget {
  final String? userRole;
  final bool certified;
  final double size;

  const InlineBadge({
    super.key,
    this.userRole,
    this.certified = false,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'ADMIN';
    final isArtist = userRole == 'ARTIST';
    if (!isAdmin && !isArtist && !certified) return const SizedBox.shrink();

    final Color color;
    final IconData icon;
    final String tooltip;
    if (isAdmin) {
      color = AppColors.badgeAdmin;
      icon = Icons.shield_rounded;
      tooltip = 'badge_admin'.tr();
    } else if (isArtist) {
      color = AppColors.badgeArtist;
      icon = Icons.verified_rounded;
      tooltip = 'badge_artist_certified'.tr();
    } else {
      color = AppColors.badgeCertified;
      icon = Icons.verified_rounded;
      tooltip = 'badge_festival_certified'.tr();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        Tooltip(message: tooltip, child: Icon(icon, size: size, color: color)),
      ],
    );
  }
}
