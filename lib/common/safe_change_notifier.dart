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
    } catch (_) {
      apply(current);
      safeNotify();
      onError?.call();
    }
  }
}
