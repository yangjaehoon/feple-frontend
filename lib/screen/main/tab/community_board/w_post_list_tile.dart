import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
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
      ),
      title: Text(
        post.title,
        style: TextStyle(
          color: colors.textTitle,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
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
              style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.6)),
            ),
        ],
      ),
      trailing: PostStatRow(
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        scrapCount: post.scrapCount,
        compact: false,
      ),
    );
  }
}
