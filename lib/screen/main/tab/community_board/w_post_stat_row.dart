import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 게시글 목록 타일 trailing용 읽기 전용 통계 행.
///
/// [scrapCount] 가 non-null 이면 별 아이콘을 하트와 댓글 사이에 표시한다.
/// [compact] — true(기본): 작은 사이즈(마이페이지 타일용), false: 큰 사이즈
class PostStatRow extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final int? scrapCount;
  final bool compact;

  const PostStatRow({
    super.key,
    required this.likeCount,
    required this.commentCount,
    this.scrapCount,
    this.compact = true,
  });

  double get _heartSize => compact ? 16 : 18;
  double get _starSize => compact ? 16 : 18;
  double get _commentSize => compact ? 15 : 16;
  double get _fontSize => compact ? 13 : 14;
  FontWeight get _fontWeight => compact ? FontWeight.normal : FontWeight.w600;
  double get _spacing => compact ? 8 : 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyle = TextStyle(
      fontSize: _fontSize,
      color: colors.textTitle,
      fontWeight: _fontWeight,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite_border_rounded,
            color: colors.likeActiveColor, size: _heartSize),
        const SizedBox(width: 4),
        Text(likeCount.toString(), style: textStyle),
        if (scrapCount != null) ...[
          SizedBox(width: _spacing),
          Icon(Icons.star_border_rounded,
              color: colors.accentColor, size: _starSize),
          const SizedBox(width: 4),
          Text(scrapCount!.toString(), style: textStyle),
        ],
        SizedBox(width: _spacing),
        Icon(Icons.chat_bubble_outline_rounded,
            color: colors.textSecondary, size: _commentSize),
        const SizedBox(width: 4),
        Text(commentCount.toString(), style: textStyle),
      ],
    );
  }
}
