import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/text_highlight.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
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

  Widget _buildSubtitle(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          post.content,
          style: TextStyle(color: colors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (post.createdAt != null)
          Text(
            post.createdAt!.relativeTime,
            style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary.withValues(alpha: 0.6)),
          ),
      ],
    );
  }

  Widget _buildTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (post.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            child: CachedNetworkImage(
              imageUrl: post.imageUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) {
                final colors = context.appColors;
                return Container(
                  width: 48,
                  height: 48,
                  color: colors.surface,
                  child: Icon(Icons.broken_image_rounded, size: 20, color: colors.textSecondary.withValues(alpha: 0.4)),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        PostStatRow(
          likeCount: post.likeCount,
          commentCount: post.commentCount,
          scrapCount: post.scrapCount,
          compact: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListTile(
      onTap: onTap,
      leading: ProfileAvatar(
        imageUrl: post.profileImageUrl,
        nickname: post.nickname,
        certified: post.certified,
        userRole: post.userRole,
        anonymous: post.anonymous,
      ),
      title: _buildTitle(colors),
      subtitle: _buildSubtitle(colors),
      trailing: _buildTrailing(),
    );
  }
}
