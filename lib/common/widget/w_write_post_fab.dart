import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

class WritePostFab extends StatelessWidget {
  final VoidCallback onPressed;

  const WritePostFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        backgroundColor: colors.activate,
        onPressed: onPressed,
        label: Text(
          'write_post'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }
}
