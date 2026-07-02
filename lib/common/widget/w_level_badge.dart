import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 게시글 옆에 표시하는 사용자 레벨 배지.
/// authorLevel이 null이면 (익명, 탈퇴 등) 빈 위젯 반환.
class LevelBadge extends StatelessWidget {
  final String? authorLevel;
  final double fontSize;

  const LevelBadge({
    super.key,
    required this.authorLevel,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final level = authorLevel;
    if (level == null) return const SizedBox.shrink();

    final colors = context.appColors;
    final (label, color) = _resolveLevel(level, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _resolveLevel(String level, AbstractThemeColors colors) {
    return switch (level) {
      'SPROUT'   => ('새싹', const Color(0xFF4CAF50)),
      'BLOOM'    => ('꽃', const Color(0xFFE91E8C)),
      'FESTIVAL' => ('페스티버', const Color(0xFF9C27B0)),
      'LEGEND'   => ('레전드', const Color(0xFFF57C00)),
      _          => ('씨앗', colors.textSecondary),
    };
  }
}
