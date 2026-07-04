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
        heroTag: null,
        backgroundColor: colors.activate,
        onPressed: onPressed,
        label: Text(
          'write_post'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700),
        ),
        icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
