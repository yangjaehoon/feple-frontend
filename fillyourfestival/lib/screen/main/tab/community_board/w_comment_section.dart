import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

/// 댓글 목록 + 입력 필드 위젯
class CommentSection extends StatelessWidget {
  final List<Map<String, dynamic>> comments;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const CommentSection({
    super.key,
    required this.comments,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '댓글을 입력하세요.',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  style: TextStyle(color: colors.textTitle),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 4),
              isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.activate,
                      ),
                    )
                  : IconButton(
                      onPressed: onSubmit,
                      icon: Icon(Icons.send_rounded,
                          color: colors.activate),
                    ),
              const SizedBox(width: 4),
            ],
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
                Text(
                  'User ${comment['userId']}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
