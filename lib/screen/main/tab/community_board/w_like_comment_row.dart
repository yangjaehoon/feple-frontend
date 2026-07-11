import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/post_interaction_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:feple/model/post_interaction_data.dart';

/// 좋아요 + 스크랩 + 댓글 수 표시 행
class LikeCommentRow extends StatelessWidget {
  final PostInteractionData interaction;
  final VoidCallback onLikeTap;
  final VoidCallback onScrapTap;

  const LikeCommentRow({
    super.key,
    required this.interaction,
    required this.onLikeTap,
    required this.onScrapTap,
  });

  Widget _buildLikeButton(AbstractThemeColors colors) {
    return Semantics(
      button: true,
      label: 'like'.tr(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onLikeTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                interaction.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: colors.likeActiveColor,
              ),
              const SizedBox(width: 4),
              Text(
                interaction.likeCount.toString(),
                style: TextStyle(fontSize: AppDimens.fontSizeXl, color: colors.textTitle, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrapButton(AbstractThemeColors colors) {
    return Semantics(
      button: true,
      label: 'scrap'.tr(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onScrapTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                interaction.scraped ? Icons.star_rounded : Icons.star_border_rounded,
                color: colors.accentColor,
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                interaction.scrapCount.toString(),
                style: TextStyle(fontSize: AppDimens.fontSizeXl, color: colors.textTitle, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        _buildLikeButton(colors),
        const SizedBox(width: 16),
        _buildScrapButton(colors),
        const SizedBox(width: 16),
        Icon(Icons.comment_rounded, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(
          interaction.commentCount.toString(),
          style: TextStyle(fontSize: AppDimens.fontSizeXl, color: colors.textTitle, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
