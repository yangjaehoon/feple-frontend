import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String content,
  String? confirmLabel,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final colors = ctx.appColors;
      return AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
        ),
        content: Text(content, style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(confirmLabel ?? 'confirm'.tr()),
          ),
        ],
      );
    },
  );
}
