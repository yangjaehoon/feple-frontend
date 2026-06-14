import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:flutter/material.dart';

/// 댓글 목록 위젯.
/// [rootComments], [repliesMap]은 PostDetailNotifier의 캐시 게터에서 전달받는다.
class CommentSection extends StatelessWidget {
  final List<CommentDetail> rootComments;
  final Map<int, List<CommentDetail>> repliesMap;
  final int? currentUserId;
  final void Function(int commentId)? onReport;
  final void Function(int commentId, String nickname)? onReply;
  final void Function(int commentId)? onToggleLike;
  final void Function(int commentId)? onDeleteComment;
  final void Function(int commentId, String currentContent)? onEditComment;

  const CommentSection({
    super.key,
    required this.rootComments,
    required this.repliesMap,
    this.currentUserId,
    this.onReport,
    this.onReply,
    this.onToggleLike,
    this.onDeleteComment,
    this.onEditComment,
  });

  Widget _buildEmpty(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'be_first_to_comment'.tr(),
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (rootComments.isEmpty) return _buildEmpty(colors);

    final items = <Widget>[];
    for (int commentIndex = 0; commentIndex < rootComments.length; commentIndex++) {
      final root = rootComments[commentIndex];
      if (commentIndex > 0) items.add(Divider(color: colors.listDivider, height: 1));
      items.add(_CommentTile(
        comment: root,
        isOwn: currentUserId != null && root.userId == currentUserId,
        onReport: onReport != null ? () => onReport!(root.id) : null,
        onReply: onReply != null ? () => onReply!(root.id, root.nickname) : null,
        onToggleLike: onToggleLike != null ? () => onToggleLike!(root.id) : null,
        onDelete: onDeleteComment != null ? () => onDeleteComment!(root.id) : null,
        onEdit: onEditComment != null ? () => onEditComment!(root.id, root.content) : null,
      ));

      final replies = repliesMap[root.id] ?? [];
      for (final reply in replies) {
        items.add(Divider(color: colors.listDivider, height: 1, indent: 48, endIndent: 0));
        items.add(Padding(
          padding: const EdgeInsets.only(left: 32),
          child: _CommentTile(
            comment: reply,
            isReply: true,
            isOwn: currentUserId != null && reply.userId == currentUserId,
            onReport: onReport != null ? () => onReport!(reply.id) : null,
            onToggleLike: onToggleLike != null ? () => onToggleLike!(reply.id) : null,
            onDelete: onDeleteComment != null ? () => onDeleteComment!(reply.id) : null,
            onEdit: onEditComment != null ? () => onEditComment!(reply.id, reply.content) : null,
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
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    this.isReply = false,
    this.onReport,
    this.onReply,
    this.onToggleLike,
    this.onDelete,
    this.onEdit,
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
            imageUrl: comment.anonymous ? null : comment.profileImageUrl,
            nickname: comment.nickname,
            certified: comment.anonymous ? false : comment.certified,
            userRole: comment.anonymous ? null : comment.userRole,
            radius: isReply ? 13 : 16,
            anonymous: comment.anonymous,
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildBody(colors)),
          _buildMenu(context, colors),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              comment.nickname,
              style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (!comment.anonymous)
              InlineBadge(userRole: comment.userRole, certified: comment.certified),
          ],
        ),
        Row(
          children: [
            Text(
              comment.createdAt.relativeTime,
              style: TextStyle(fontSize: AppDimens.fontSizeTiny, color: colors.textSecondary.withValues(alpha: 0.6)),
            ),
            if (comment.isEdited) ...[
              const SizedBox(width: 4),
              Text(
                'edited'.tr(),
                style: TextStyle(fontSize: 9, color: colors.textSecondary.withValues(alpha: 0.45)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(comment.content, style: TextStyle(color: colors.textTitle)),
        const SizedBox(height: 4),
        _buildActions(colors),
      ],
    );
  }

  Widget _buildActions(AbstractThemeColors colors) {
    return Row(
      children: [
        GestureDetector(
          onTap: onToggleLike,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                comment.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 13,
                color: comment.liked ? AppColors.kawaiiPink : colors.textSecondary,
              ),
              if (comment.likeCount > 0) ...[
                const SizedBox(width: 3),
                Text(
                  comment.likeCount.toString(),
                  style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
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
              style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenu(BuildContext context, AbstractThemeColors colors) {
    if (isOwn) {
      return PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, size: 16, color: colors.textSecondary),
        onSelected: (value) async {
          if (value == 'edit') {
            onEdit?.call();
          } else if (value == 'delete') {
            final confirmed = await showConfirmDialog(
              context,
              title: 'delete_comment'.tr(),
              content: 'delete_comment_confirm'.tr(),
              confirmLabel: 'delete_comment'.tr(),
            );
            if (confirmed) onDelete?.call();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              const Icon(Icons.edit_outlined, size: 16),
              const SizedBox(width: 8),
              Text('edit_comment'.tr(), style: const TextStyle(fontSize: 13)),
            ]),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorRed),
              const SizedBox(width: 8),
              Text('delete_comment'.tr(), style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
            ]),
          ),
        ],
      );
    }
    if (onReport != null) {
      return PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, size: 16, color: colors.textSecondary),
        onSelected: (value) {
          if (value == 'report') onReport!();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'report',
            child: Row(children: [
              const Icon(Icons.flag_outlined, size: 16, color: AppColors.errorRed),
              const SizedBox(width: 8),
              Text('report_comment'.tr(), style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
            ]),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
