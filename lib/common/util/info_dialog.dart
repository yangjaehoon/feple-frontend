import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_alert_dialog.dart';
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
    builder: (ctx) => buildAppAlertDialog(
      ctx,
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(confirmLabel ?? 'confirm'.tr()),
        ),
      ],
    ),
  );
}
