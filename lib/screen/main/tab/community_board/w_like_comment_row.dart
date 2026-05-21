import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            color: AppColors.kawaiiPink, size: _heartSize),
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

class PostInteractionData {
  final bool liked;
  final int heartCount;
  final int commentCount;
  final bool scraped;
  final int scrapCount;

  const PostInteractionData({
    required this.liked,
    required this.heartCount,
    required this.commentCount,
    required this.scraped,
    required this.scrapCount,
  });
}

/// 좋아요 + 스크랩 + 댓글 수 표시 행
class LikeCommentRow extends StatelessWidget {
  final PostInteractionData data;
  final VoidCallback onLikeTap;
  final VoidCallback onScrapTap;

  const LikeCommentRow({
    super.key,
    required this.data,
    required this.onLikeTap,
    required this.onScrapTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        // 좋아요
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onLikeTap();
          },
          child: Row(
            children: [
              Icon(
                data.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.kawaiiPink,
              ),
              const SizedBox(width: 4),
              Text(
                data.heartCount.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 스크랩
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onScrapTap();
          },
          child: Row(
            children: [
              Icon(
                data.scraped ? Icons.star_rounded : Icons.star_border_rounded,
                color: colors.accentColor,
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                data.scrapCount.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 댓글
        Icon(Icons.comment_rounded, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(
          data.commentCount.toString(),
          style: TextStyle(
            fontSize: 16,
            color: colors.textTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
