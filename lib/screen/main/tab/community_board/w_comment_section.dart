import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/popup_menu_item_builder.dart';
import 'package:feple/common/widget/w_expandable_text.dart';
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
  final Future<bool> Function(int commentId)? onToggleLike;
  final void Function(int commentId)? onDeleteComment;
  final void Function(int commentId, String currentContent)? onEditComment;
  final void Function(int userId, String nickname, String? profileImageUrl)? onAuthorTap;

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
    this.onAuthorTap,
  });

  Widget _buildEmpty(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'be_first_to_comment'.tr(),
          style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
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
        onAuthorTap: onAuthorTap != null && !root.anonymous
            ? () => onAuthorTap!(root.userId, root.nickname, root.profileImageUrl)
            : null,
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
            onAuthorTap: onAuthorTap != null && !reply.anonymous
                ? () => onAuthorTap!(reply.userId, reply.nickname, reply.profileImageUrl)
                : null,
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
  final Future<bool> Function()? onToggleLike;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onAuthorTap;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    this.isReply = false,
    this.onReport,
    this.onReply,
    this.onToggleLike,
    this.onDelete,
    this.onEdit,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: Padding(
              padding: EdgeInsets.all(isReply ? 11.0 : 8.0),
              child: ProfileAvatar(
                imageUrl: comment.anonymous ? null : comment.profileImageUrl,
                nickname: comment.nickname,
                certified: comment.anonymous ? false : comment.certified,
                userRole: comment.anonymous ? null : comment.userRole,
                radius: isReply ? 13 : 16,
                anonymous: comment.anonymous,
              ),
            ),
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
              style: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXs, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: AppDimens.fontSizeMini, color: colors.textSecondary.withValues(alpha: 0.45)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        ExpandableText(text: comment.content, style: TextStyle(color: colors.textTitle)),
        const SizedBox(height: 4),
        _buildActions(colors),
      ],
    );
  }

  Widget _buildActions(AbstractThemeColors colors) {
    return Row(
      children: [
        _LikeButton(
          liked: comment.liked,
          likeCount: comment.likeCount,
          onToggle: onToggleLike,
        ),
        if (!isReply && onReply != null) ...[
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: 'reply_comment'.tr(),
            child: SizedBox(
              height: AppDimens.minTouchTarget,
              child: GestureDetector(
                onTap: onReply,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Text(
                      'reply_comment'.tr(),
                      style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenu(BuildContext context, AbstractThemeColors colors) {
    if (isOwn) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 16, color: colors.textSecondary),
        color: colors.surface,
        elevation: 3,
        shadowColor: colors.cardShadow.withValues(alpha: 0.18),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimens.shapeDialog))),
        position: PopupMenuPosition.under,
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
          buildPopupMenuItem(
            value: 'edit',
            icon: Icons.edit_outlined,
            label: 'edit_comment'.tr(),
            colors: colors,
            fontSize: AppDimens.fontSizeSm,
          ),
          const PopupMenuDivider(height: 1),
          buildPopupMenuItem(
            value: 'delete',
            icon: Icons.delete_outline_rounded,
            label: 'delete_comment'.tr(),
            colors: colors,
            danger: true,
            fontSize: AppDimens.fontSizeSm,
          ),
        ],
      );
    }
    if (onReport != null) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 16, color: colors.textSecondary),
        color: colors.surface,
        elevation: 3,
        shadowColor: colors.cardShadow.withValues(alpha: 0.18),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimens.shapeDialog))),
        position: PopupMenuPosition.under,
        onSelected: (value) {
          if (value == 'report') onReport!();
        },
        itemBuilder: (_) => [
          buildPopupMenuItem(
            value: 'report',
            icon: Icons.flag_outlined,
            label: 'report_comment'.tr(),
            colors: colors,
            danger: true,
            fontSize: AppDimens.fontSizeSm,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

/// 댓글 좋아요 버튼.
/// 탭 즉시 로컬 상태로 낙관적 반영하고 [onToggle] 결과가 실패면 되돌린다.
/// 상위 [CommentSection]의 commentsVersion을 올리지 않아, 댓글 하나를 좋아요
/// 눌러도 전체 댓글 리스트가 다시 빌드되지 않는다.
class _LikeButton extends StatefulWidget {
  final bool liked;
  final int likeCount;
  final Future<bool> Function()? onToggle;

  const _LikeButton({required this.liked, required this.likeCount, this.onToggle});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  late bool _liked = widget.liked;
  late int _likeCount = widget.likeCount;

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 댓글 수정/삭제 등 다른 이유로 부모가 새 comment 데이터를 내려주면 동기화
    if (oldWidget.liked != widget.liked || oldWidget.likeCount != widget.likeCount) {
      _liked = widget.liked;
      _likeCount = widget.likeCount;
    }
  }

  Future<void> _handleTap() async {
    final onToggle = widget.onToggle;
    if (onToggle == null) return;
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    final success = await onToggle();
    if (!success && mounted) {
      setState(() {
        _liked = !_liked;
        _likeCount += _liked ? 1 : -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: 'like'.tr(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppDimens.minTouchTarget,
          minHeight: AppDimens.minTouchTarget,
        ),
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 13,
                    color: _liked ? colors.likeActiveColor : colors.textSecondary,
                  ),
                  if (_likeCount > 0) ...[
                    const SizedBox(width: 3),
                    Text(
                      _likeCount.toString(),
                      style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
