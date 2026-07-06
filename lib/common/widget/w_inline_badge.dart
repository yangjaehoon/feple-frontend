import 'package:feple/common/common.dart';
import 'package:feple/common/constant/user_roles.dart';
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
    final isAdmin = userRole == kRoleAdmin;
    final isArtist = userRole == kRoleArtist;
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
      // artist 배지와 아이콘이 같으면 색약 사용자가 색상만으로 구분해야 함 — 아이콘도 다르게
      icon = Icons.local_activity_rounded;
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
