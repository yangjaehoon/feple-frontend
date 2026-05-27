import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:flutter/material.dart';

/// 댓글 목록 위젯
class CommentSection extends StatelessWidget {
  final List<CommentDetail> comments;
  final int? currentUserId;
  final void Function(int commentId)? onReport;
  final void Function(int commentId, String nickname)? onReply;
  final void Function(int commentId)? onToggleLike;

  const CommentSection({
    super.key,
    required this.comments,
    this.currentUserId,
    this.onReport,
    this.onReply,
    this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (comments.isEmpty) return const SizedBox.shrink();

    // 루트 댓글 / 대댓글 분리
    final roots = comments.where((c) => c.parentId == null).toList();
    final repliesMap = <int, List<CommentDetail>>{};
    for (final c in comments) {
      if (c.parentId != null) {
        repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    final items = <Widget>[];
    for (int i = 0; i < roots.length; i++) {
      final root = roots[i];
      if (i > 0) items.add(Divider(color: colors.listDivider, height: 1));
      items.add(_CommentTile(
        comment: root,
        isOwn: currentUserId != null && root.userId == currentUserId,
        onReport: onReport != null ? () => onReport!(root.id) : null,
        onReply: onReply != null ? () => onReply!(root.id, root.nickname) : null,
        onToggleLike: onToggleLike != null ? () => onToggleLike!(root.id) : null,
      ));

      final replies = repliesMap[root.id] ?? [];
      for (final reply in replies) {
        items.add(Divider(
            color: colors.listDivider, height: 1, indent: 48, endIndent: 0));
        items.add(Padding(
          padding: const EdgeInsets.only(left: 32),
          child: _CommentTile(
            comment: reply,
            isReply: true,
            isOwn: currentUserId != null && reply.userId == currentUserId,
            onReport: onReport != null ? () => onReport!(reply.id) : null,
            onToggleLike: onToggleLike != null ? () => onToggleLike!(reply.id) : null,
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

/// 개별 댓글 타일
class _CommentTile extends StatelessWidget {
  final CommentDetail comment;
  final bool isOwn;
  final bool isReply;
  final VoidCallback? onReport;
  final VoidCallback? onReply;
  final VoidCallback? onToggleLike;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    this.isReply = false,
    this.onReport,
    this.onReply,
    this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            imageUrl: comment.profileImageUrl,
            nickname: comment.nickname,
            certified: comment.certified,
            userRole: comment.userRole,
            radius: isReply ? 13 : 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.nickname,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InlineBadge(
                      userRole: comment.userRole,
                      certified: comment.certified,
                    ),
                  ],
                ),
                Text(
                  comment.createdAt.relativeTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: TextStyle(color: colors.textTitle),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onToggleLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 13,
                            color: comment.liked
                                ? AppColors.kawaiiPink
                                : colors.textSecondary,
                          ),
                          if (comment.likeCount > 0) ...[
                            const SizedBox(width: 3),
                            Text(
                              comment.likeCount.toString(),
                              style: TextStyle(
                                  fontSize: 11, color: colors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isReply && onReply != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          'reply_comment'.tr(),
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isOwn && onReport != null)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert,
                  size: 16, color: colors.textSecondary),
              onSelected: (value) {
                if (value == 'report') onReport!();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('report_comment'.tr(),
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
