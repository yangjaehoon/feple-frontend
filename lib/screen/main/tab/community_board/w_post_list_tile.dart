import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/text_highlight.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_stat_row.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/responsive_size.dart';

/// 게시글 목록에서 한 줄 타일
class PostListTile extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final String? highlightKeyword;
  final VoidCallback? onAuthorTap;

  const PostListTile({
    super.key,
    required this.post,
    required this.onTap,
    this.highlightKeyword,
    this.onAuthorTap,
  });

  Widget _buildTitle(AbstractThemeColors colors) {
    return buildHighlightedText(
      post.title,
      highlightKeyword,
      TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
      colors.activate,
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Semantics(
      button: !post.anonymous && onAuthorTap != null,
      label: post.anonymous ? null : 'view_author_profile'.tr(args: [post.nickname]),
      child: GestureDetector(
        onTap: (!post.anonymous && onAuthorTap != null) ? onAuthorTap : null,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ProfileAvatar(
            imageUrl: post.profileImageUrl,
            nickname: post.nickname,
            certified: post.certified,
            userRole: post.userRole,
            anonymous: post.anonymous,
            radius: ResponsiveSize(context).w(20),
          ),
        ),
      ),
    );
  }

  Widget _buildTextColumn(AbstractThemeColors colors) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(colors),
          const SizedBox(height: AppDimens.space4),
          Text(
            post.content,
            style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.space6),
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
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final size = ResponsiveSize(context).w(56);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          child: CachedNetworkImage(
            imageUrl: post.imageUrls.first,
            width: size,
            height: size,
            memCacheWidth: 112, // 56px * 2 (Retina)
            fit: BoxFit.cover,
            fadeInDuration: AppDimens.animXFast,
            fadeOutDuration: AppDimens.animTapFeedback,
            placeholder: (context, _) {
              final c = context.appColors;
              return Container(width: size, height: size, color: c.surface);
            },
            errorWidget: (context, url, error) {
              final c = context.appColors;
              return Container(
                width: size,
                height: size,
                color: c.surface,
                child: Icon(
                  Icons.broken_image_rounded,
                  size: 20,
                  color: c.textSecondary.withValues(alpha: 0.4),
                ),
              );
            },
          ),
        ),
        if (post.imageUrls.length > 1)
          Positioned(
            top: 3,
            right: 3,
            child: Icon(
              Icons.photo_library_rounded,
              size: 14,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 3),
              ],
            ),
          ),
      ],
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
            _buildAvatar(context),
            const SizedBox(width: AppDimens.space12),
            _buildTextColumn(colors),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(width: AppDimens.space12),
              _buildThumbnail(context),
            ],
          ],
        ),
      ),
    );
  }
}
