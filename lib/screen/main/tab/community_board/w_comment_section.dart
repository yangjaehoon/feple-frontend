import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 댓글 목록 위젯
class CommentSection extends StatelessWidget {
  final List<Map<String, dynamic>> comments;
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
    final roots = comments.where((c) => c['parentId'] == null).toList();
    final repliesMap = <int, List<Map<String, dynamic>>>{};
    for (final c in comments) {
      final pid = c['parentId'];
      if (pid != null) {
        repliesMap.putIfAbsent(pid as int, () => []).add(c);
      }
    }

    final items = <Widget>[];
    for (int i = 0; i < roots.length; i++) {
      final root = roots[i];
      if (i > 0) items.add(Divider(color: colors.listDivider, height: 1));
      items.add(_CommentTile(
        comment: root,
        isOwn: currentUserId != null && root['userId'] == currentUserId,
        onReport: onReport != null ? () => onReport!(root['id'] as int) : null,
        onReply: onReply != null
            ? () => onReply!(
                root['id'] as int,
                root['nickname'] as String? ?? 'User')
            : null,
        onToggleLike: onToggleLike != null
            ? () => onToggleLike!(root['id'] as int)
            : null,
      ));

      final replies = repliesMap[root['id'] as int] ?? [];
      for (final reply in replies) {
        items.add(Divider(
            color: colors.listDivider, height: 1, indent: 48, endIndent: 0));
        items.add(Padding(
          padding: const EdgeInsets.only(left: 32),
          child: _CommentTile(
            comment: reply,
            isReply: true,
            isOwn: currentUserId != null && reply['userId'] == currentUserId,
            onReport: onReport != null ? () => onReport!(reply['id'] as int) : null,
            onToggleLike: onToggleLike != null
                ? () => onToggleLike!(reply['id'] as int)
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

/// 댓글 입력 필드 (하단 고정용)
class CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? errorText;
  final String? replyToNickname;
  final VoidCallback? onCancelReply;

  const CommentInputBar({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorText,
    this.replyToNickname,
    this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      color: colors.backgroundMain,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom > 0 ? bottom + 8 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyToNickname != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.listDivider),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 14, color: colors.activate),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$replyToNickname ${'reply_to'.tr()}',
                      style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: Icon(Icons.close, size: 14, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.listDivider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLength: 300,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: replyToNickname != null
                          ? 'enter_reply'.tr()
                          : 'enter_comment'.tr(),
                      hintStyle: TextStyle(color: colors.textSecondary),
                      filled: true,
                      fillColor: Colors.transparent,
                      counterText: '',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(color: colors.textTitle),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: isSubmitting
                      ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.activate,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onSubmit();
                          },
                          icon: Icon(Icons.send_rounded, color: colors.activate),
                        ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          if (errorText != null && errorText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                errorText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 개별 댓글 타일
class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
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
    final bool liked = comment['liked'] as bool? ?? false;
    final int likeCount = (comment['likeCount'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 13 : 16,
            backgroundColor: colors.activate,
            child: Icon(Icons.person,
                size: isReply ? 14 : 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['nickname'] as String? ??
                          'User ${comment['userId']}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (comment['userRole'] == 'ADMIN') ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_admin'.tr(),
                        child: const Icon(Icons.shield_rounded,
                            size: 12, color: AppColors.badgeAdmin),
                      ),
                    ] else if (comment['userRole'] == 'ARTIST') ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_artist_certified'.tr(),
                        child: const Icon(Icons.verified_rounded,
                            size: 12, color: AppColors.badgeArtist),
                      ),
                    ] else if (comment['certified'] == true) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_festival_certified'.tr(),
                        child: const Icon(Icons.verified_rounded,
                            size: 12, color: AppColors.badgeCertified),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment['content'] as String,
                  style: TextStyle(color: colors.textTitle),
                ),
                const SizedBox(height: 4),
                // 좋아요 / 답글 버튼
                Row(
                  children: [
                    GestureDetector(
                      onTap: onToggleLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 13,
                            color: liked
                                ? AppColors.kawaiiPink
                                : colors.textSecondary,
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 3),
                            Text(
                              likeCount.toString(),
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
