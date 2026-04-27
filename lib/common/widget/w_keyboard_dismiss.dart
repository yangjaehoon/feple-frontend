import 'package:flutter/material.dart';

/// 빈 영역 탭 시 키보드를 닫는 래퍼 위젯
class KeyboardDismiss extends StatelessWidget {
  final Widget child;

  const KeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
