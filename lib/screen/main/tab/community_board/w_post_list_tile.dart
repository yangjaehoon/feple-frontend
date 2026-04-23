import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/model/post_model.dart';
import 'package:flutter/material.dart';

/// 게시글 목록에서 한 줄 타일
class PostListTile extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostListTile({
    super.key,
    required this.post,
    required this.onTap,
  });

  bool get _hasCustomImage {
    final url = post.profileImageUrl;
    return url != null && !url.contains('feple_logo');
  }

  Widget _buildAvatar(AbstractThemeColors colors) {
    final avatar = _hasCustomImage
        ? CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(post.profileImageUrl!),
            backgroundColor: colors.activate,
          )
        : CircleAvatar(
            backgroundColor: colors.activate,
            child: Text(
              post.nickname.isNotEmpty ? post.nickname[0] : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    final hasBadge = post.certified || post.isAdmin || post.isArtist;
    if (!hasBadge) return avatar;

    Color badgeColor;
    IconData badgeIcon;
    String badgeTooltip;
    if (post.isAdmin) {
      badgeColor = Colors.deepPurple;
      badgeIcon = Icons.shield_rounded;
      badgeTooltip = '관리자';
    } else if (post.isArtist) {
      badgeColor = Colors.blue;
      badgeIcon = Icons.verified_rounded;
      badgeTooltip = '아티스트 인증';
    } else {
      badgeColor = Colors.teal;
      badgeIcon = Icons.verified_rounded;
      badgeTooltip = '페스티벌 인증 완료';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Tooltip(
            message: badgeTooltip,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, size: 11, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListTile(
      onTap: onTap,
      title: Text(
        post.title,
        style: TextStyle(
          color: colors.textTitle,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        post.content,
        style: TextStyle(color: colors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border_rounded,
              color: AppColors.kawaiiPink, size: 18),
          const SizedBox(width: 4),
          Text(
            post.likeCount.toString(),
            style: TextStyle(
              fontSize: 14,
              color: colors.textTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.comment_rounded, color: colors.textSecondary, size: 16),
          const SizedBox(width: 4),
          Text(
            post.commentCount.toString(),
            style: TextStyle(
              fontSize: 14,
              color: colors.textTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      leading: _buildAvatar(colors),
    );
  }
}
