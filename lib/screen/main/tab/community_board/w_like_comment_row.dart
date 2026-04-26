import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 좋아요 + 댓글 수 + 스크랩 표시 행
class LikeCommentRow extends StatelessWidget {
  final bool liked;
  final int heartCount;
  final int commentCount;
  final bool scraped;
  final VoidCallback onLikeTap;
  final VoidCallback onScrapTap;

  const LikeCommentRow({
    super.key,
    required this.liked,
    required this.heartCount,
    required this.commentCount,
    required this.scraped,
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
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.kawaiiPink,
              ),
              const SizedBox(width: 4),
              Text(
                heartCount.toString(),
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
          commentCount.toString(),
          style: TextStyle(
            fontSize: 16,
            color: colors.textTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // 스크랩
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onScrapTap();
          },
          child: Icon(
            scraped ? Icons.star_rounded : Icons.star_border_rounded,
            color: scraped ? AppColors.sunnyYellow : colors.textSecondary,
            size: 26,
          ),
        ),
      ],
    );
  }
}
