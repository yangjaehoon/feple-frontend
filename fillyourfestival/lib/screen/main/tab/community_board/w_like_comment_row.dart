import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

/// 좋아요 + 댓글 수 표시 행
class LikeCommentRow extends StatelessWidget {
  final bool liked;
  final int heartCount;
  final int commentCount;
  final VoidCallback onLikeTap;

  const LikeCommentRow({
    super.key,
    required this.liked,
    required this.heartCount,
    required this.commentCount,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        GestureDetector(
          onTap: onLikeTap,
          child: Row(
            children: [
              Icon(
                liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
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
      ],
    );
  }
}
