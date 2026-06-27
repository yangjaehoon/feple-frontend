import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/text_highlight.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 게시글 목록에서 한 줄 타일
class PostListTile extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final String? highlightKeyword;

  const PostListTile({
    super.key,
    required this.post,
    required this.onTap,
    this.highlightKeyword,
  });

  Widget _buildTitle(AbstractThemeColors colors) {
    return buildHighlightedText(
      post.title,
      highlightKeyword,
      TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
      colors.activate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileAvatar(
              imageUrl: post.profileImageUrl,
              nickname: post.nickname,
              certified: post.certified,
              userRole: post.userRole,
              anonymous: post.anonymous,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(colors),
                  const SizedBox(height: 4),
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeSm,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: PostStatRow(
                          likeCount: post.likeCount,
                          commentCount: post.commentCount,
                          scrapCount: post.scrapCount,
                          compact: true,
                        ),
                      ),
                      if (post.createdAt != null)
                        Text(
                          post.createdAt!.relativeTime,
                          style: TextStyle(
                            fontSize: AppDimens.fontSizeXxs,
                            color: colors.textSecondary.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: 56,
                  height: 56,
                  memCacheWidth: 112, // 56px * 2 (Retina)
                  fit: BoxFit.cover,
                  fadeInDuration: AppDimens.animXFast,
                  fadeOutDuration: AppDimens.animTapFeedback,
                  placeholder: (context, _) {
                    final c = context.appColors;
                    return Container(width: 56, height: 56, color: c.surface);
                  },
                  errorWidget: (context, url, error) {
                    final c = context.appColors;
                    return Container(
                      width: 56,
                      height: 56,
                      color: c.surface,
                      child: Icon(Icons.broken_image_rounded, size: 20, color: c.textSecondary.withValues(alpha: 0.4)),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
