import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
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
          borderRadius: BorderRadius.all(Radius.circular(AppDimens.shapeDialog)),
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
