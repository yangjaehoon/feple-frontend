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
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(confirmLabel ?? 'confirm'.tr()),
        ),
      ],
    ),
  );
}
