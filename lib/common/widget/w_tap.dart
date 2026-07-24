import 'package:flutter/material.dart';

class Tap extends StatelessWidget {
  final void Function() onTap;
  final void Function()? onLongPress;
  final Widget child;
  final String? semanticsLabel;

  const Tap({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        label: semanticsLabel,
        button: semanticsLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: child,
        ),
      ),
    );
  }
}
