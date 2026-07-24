import 'package:feple/common/common.dart';
import 'package:feple/common/constant/user_roles.dart';
import 'package:flutter/material.dart';

/// 관리자/아티스트/인증 뱃지의 색상+아이콘+툴팁.
class RoleBadgeStyle {
  final Color color;
  final IconData icon;
  final String tooltip;

  const RoleBadgeStyle({required this.color, required this.icon, required this.tooltip});
}

/// 뱃지가 필요 없으면(관리자도 아티스트도 인증도 아니면) null 반환.
/// 우선순위: 관리자 > 아티스트 > 페스티벌 인증.
RoleBadgeStyle? roleBadgeStyleFor({String? userRole, bool certified = false}) {
  final isAdmin = userRole == kRoleAdmin;
  final isArtist = userRole == kRoleArtist;
  if (!isAdmin && !isArtist && !certified) return null;

  if (isAdmin) {
    return RoleBadgeStyle(
      color: AppColors.badgeAdmin,
      icon: Icons.shield_rounded,
      tooltip: 'badge_admin'.tr(),
    );
  }
  if (isArtist) {
    return RoleBadgeStyle(
      color: AppColors.badgeArtist,
      icon: Icons.verified_rounded,
      tooltip: 'badge_artist_certified'.tr(),
    );
  }
  // artist 배지와 아이콘이 같으면 색약 사용자가 색상만으로 구분해야 함 — 아이콘도 다르게
  return RoleBadgeStyle(
    color: AppColors.badgeCertified,
    icon: Icons.local_activity_rounded,
    tooltip: 'badge_festival_certified'.tr(),
  );
}
