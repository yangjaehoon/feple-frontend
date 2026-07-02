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

  @override
  Widget build(BuildContext context) {
    final emoji = _emoji(authorLevel);
    if (emoji == null) return const SizedBox.shrink();

    return Tooltip(
      message: _label(authorLevel),
      child: Text(emoji, style: TextStyle(fontSize: fontSize)),
    );
  }

  static String? _emoji(String? level) => switch (level) {
        'SEED'     => '🌰',
        'SPROUT'   => '🌱',
        'BLOOM'    => '🌸',
        'FESTIVAL' => '🎪',
        'LEGEND'   => '👑',
        _          => null,
      };

  static String _label(String? level) => switch (level) {
        'SEED'     => '씨앗',
        'SPROUT'   => '새싹',
        'BLOOM'    => '꽃',
        'FESTIVAL' => '페스티버',
        'LEGEND'   => '레전드',
        _          => '',
      };
}
