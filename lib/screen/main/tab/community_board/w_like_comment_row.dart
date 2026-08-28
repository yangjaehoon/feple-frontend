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

  Widget _buildStatButton(
    AbstractThemeColors colors,
    String lang, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required int count,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppDimens.space4),
              Text(
                count.toDisplayCount(lang),
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
    final lang = context.locale.languageCode;
    return Row(
      children: [
        _buildStatButton(
          colors, lang,
          label: 'like'.tr(),
          icon: interaction.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: colors.likeActiveColor,
          count: interaction.likeCount,
          onTap: onLikeTap,
        ),
        const SizedBox(width: AppDimens.space16),
        _buildStatButton(
          colors, lang,
          label: 'scrap'.tr(),
          icon: interaction.scraped ? Icons.star_rounded : Icons.star_border_rounded,
          iconColor: colors.accentColor,
          count: interaction.scrapCount,
          onTap: onScrapTap,
        ),
        const SizedBox(width: AppDimens.space16),
        Icon(Icons.comment_rounded, color: colors.textSecondary),
        const SizedBox(width: AppDimens.space4),
        Text(
          interaction.commentCount.toDisplayCount(lang),
          style: TextStyle(fontSize: AppDimens.fontSizeXl, color: colors.textTitle, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
