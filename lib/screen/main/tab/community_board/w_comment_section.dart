import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 댓글 목록 + 입력 필드 위젯
class CommentSection extends StatelessWidget {
  final List<Map<String, dynamic>> comments;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? errorText;

  const CommentSection({
    super.key,
    required this.comments,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 댓글 리스트 ──
        if (comments.isNotEmpty)
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: comments.length,
            separatorBuilder: (_, __) => Divider(
              color: colors.listDivider,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final c = comments[index];
              return _CommentTile(comment: c);
            },
          ),
        const SizedBox(height: 16),

        // ── 댓글 입력 ──
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
                    hintText: 'enter_comment'.tr(),
                    hintStyle: TextStyle(color: colors.textSecondary),
                    filled: true,
                    fillColor: Colors.transparent,
                    counterText: '',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// 개별 댓글 타일
class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.activate,
            child: const Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['nickname'] as String? ?? 'User ${comment['userId']}',
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
                        child: const Icon(Icons.shield_rounded, size: 12, color: Colors.deepPurple),
                      ),
                    ] else if (comment['userRole'] == 'ARTIST') ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_artist_certified'.tr(),
                        child: const Icon(Icons.verified_rounded, size: 12, color: Colors.blue),
                      ),
                    ] else if (comment['certified'] == true) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_festival_certified'.tr(),
                        child: const Icon(Icons.verified_rounded, size: 12, color: Colors.teal),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment['content'] as String,
                  style: TextStyle(color: colors.textTitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
