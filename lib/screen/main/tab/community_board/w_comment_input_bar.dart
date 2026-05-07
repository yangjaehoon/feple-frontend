import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
