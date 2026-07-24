import 'package:feple/common/widget/role_badge_style.dart';
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
    final style = roleBadgeStyleFor(userRole: userRole, certified: certified);
    if (style == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        Tooltip(message: style.tooltip, child: Icon(style.icon, size: size, color: style.color)),
      ],
    );
  }
}
