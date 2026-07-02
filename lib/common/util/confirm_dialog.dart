import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
}) async {
  return await showDialog<bool>(
    context: context,
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      );
    },
  ) ?? false;
}
