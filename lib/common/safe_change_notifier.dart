import 'package:flutter/foundation.dart';

abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// 낙관적 토글: apply(!current) → notify → action() → 실패 시 apply(current) → notify
  @protected
  Future<void> optimisticToggle(
    bool current, {
    required void Function(bool) apply,
    required Future<void> Function() action,
    void Function()? onError,
    void Function(bool newValue)? onSuccess,
  }) async {
    final newValue = !current;
    apply(newValue);
    safeNotify();
    try {
      await action();
      onSuccess?.call(newValue);
    } catch (e) {
      // 낙관적 토글은 CQS상 예외를 던지지 않고 이전 값으로 복원한다.
      // 다만 네트워크 오류뿐 아니라 action 내부의 프로그래밍 오류도 여기서
      // 삼켜지므로 디버그 로그는 남긴다.
      debugPrint('[optimisticToggle] 실패, 이전 값으로 복원: $e');
      apply(current);
      safeNotify();
      onError?.call();
    }
  }
}
