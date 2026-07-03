import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommentInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final void Function(bool anonymous) onSubmit;
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
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  bool _anonymous = false;

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
          if (widget.replyToNickname != null) _buildReplyBanner(colors),
          _buildAnonymousToggle(colors),
          _buildInputRow(colors),
          if (widget.errorText != null && widget.errorText!.isNotEmpty) _buildErrorText(colors),
        ],
      ),
    );
  }

  Widget _buildReplyBanner(AbstractThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: colors.listDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 14, color: colors.activate),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${widget.replyToNickname} ${'reply_to'.tr()}',
              style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Semantics(
            button: true,
            label: 'cancel_reply'.tr(),
            child: GestureDetector(
              onTap: widget.onCancelReply,
              child: Icon(Icons.close, size: 14, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousToggle(AbstractThemeColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _anonymous = !_anonymous);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v ?? false),
              visualDensity: VisualDensity.compact,
              activeColor: colors.activate,
            ),
            const SizedBox(width: 6),
            Text(
              'post_anonymous'.tr(),
              style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(AbstractThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        border: Border.all(color: colors.listDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLength: 300,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.replyToNickname != null
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
            child: widget.isSubmitting
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
                    tooltip: 'send_comment'.tr(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onSubmit(_anonymous);
                    },
                    icon: Icon(Icons.send_rounded, color: colors.activate),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildErrorText(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        widget.errorText!,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXs,
          color: colors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
