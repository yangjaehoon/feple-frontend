import 'package:flutter/widgets.dart';

/// 중복 탭으로 인한 화면 중복 push 방지 가드.
/// 이미 진행 중이면 무시하고, action 완료(성공/실패 무관) 후 자동 해제한다.
mixin NavigationGuard<T extends StatefulWidget> on State<T> {
  bool _isNavigating = false;

  Future<void> guardedNavigate(Future<void> Function() action) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await action();
    } finally {
      if (mounted) _isNavigating = false;
    }
  }
}
