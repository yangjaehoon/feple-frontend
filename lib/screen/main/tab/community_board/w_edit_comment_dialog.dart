import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class EditCommentDialog extends StatefulWidget {
  final String initialContent;

  const EditCommentDialog({super.key, required this.initialContent});

  @override
  State<EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<EditCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppDimens.shapeDialog)),
      ),
      title: Text(
        'edit_comment'.tr(),
        style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
      ),
      content: Semantics(
        label: 'enter_comment'.tr(),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(context, _controller.text.trim()),
          decoration: InputDecoration(hintText: 'enter_comment'.tr()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text('done'.tr()),
        ),
      ],
    );
  }
}
