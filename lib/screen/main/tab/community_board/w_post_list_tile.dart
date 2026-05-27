import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
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

  List<TextSpan> _buildHighlightedSpans(String text, String keyword, TextStyle base, Color highlightColor) {
    if (keyword.isEmpty) return [TextSpan(text: text, style: base)];
    final pattern = RegExp(RegExp.escape(keyword), caseSensitive: false);
    final spans = <TextSpan>[];
    int last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: base.copyWith(color: highlightColor, fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last), style: base));
    return spans;
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
      ),
      title: highlightKeyword != null && highlightKeyword!.isNotEmpty
          ? RichText(
              text: TextSpan(
                children: _buildHighlightedSpans(
                  post.title,
                  highlightKeyword!,
                  TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
                  colors.activate,
                ),
              ),
            )
          : Text(
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (post.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
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
      ),
    );
  }
}
