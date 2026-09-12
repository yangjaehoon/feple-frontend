import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 닉네임 옆에 표시하는 사용자 레벨 이모티콘.
/// authorLevel이 null이거나 익명이면 빈 위젯 반환.
class LevelBadge extends StatelessWidget {
  final String? authorLevel;
  final double fontSize;

  const LevelBadge({
    super.key,
    required this.authorLevel,
    this.fontSize = 14,
  });

  static const Map<String, (String emoji, String labelKey)> _levels = {
    'SEED': ('🌰', 'level_seed'),
    'SPROUT': ('🌱', 'level_sprout'),
    'BLOOM': ('🌸', 'level_bloom'),
    'FESTIVAL': ('🎪', 'level_festival'),
    'LEGEND': ('👑', 'level_legend'),
  };

  @override
  Widget build(BuildContext context) {
    final level = _levels[authorLevel];
    if (level == null) return const SizedBox.shrink();
    final (emoji, labelKey) = level;

    return Tooltip(
      message: labelKey.tr(),
      child: Text(emoji, style: TextStyle(fontSize: fontSize)),
    );
  }
}
