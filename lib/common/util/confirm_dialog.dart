import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_alert_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => buildAppAlertDialog(
      ctx,
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: ctx.appColors.error),
          ),
        ),
      ],
    ),
  ) ?? false;
}
