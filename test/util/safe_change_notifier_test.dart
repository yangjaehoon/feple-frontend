import 'package:feple/common/safe_change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestNotifier extends SafeChangeNotifier {
  bool value = false;

  Future<void> toggle({required Future<void> Function() action, void Function()? onError}) =>
      optimisticToggle(
        value,
        apply: (v) => value = v,
        action: action,
        onError: onError,
      );
}

void main() {
  group('SafeChangeNotifier.safeNotify', () {
    test('dispose 이후에는 리스너를 호출하지 않는다', () {
      final notifier = _TestNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);

      notifier.dispose();
      notifier.safeNotify();

      expect(notified, isFalse);
      expect(notifier.isDisposed, isTrue);
    });

    test('dispose 이전에는 리스너를 호출한다', () {
      final notifier = _TestNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);

      notifier.safeNotify();

      expect(notified, isTrue);
    });
  });

  group('SafeChangeNotifier.optimisticToggle', () {
    test('action이 성공하면 값이 반전된 채로 유지된다', () async {
      final notifier = _TestNotifier();

      await notifier.toggle(action: () async {});

      expect(notifier.value, isTrue);
    });

    test('action이 실패하면 이전 값으로 복원된다', () async {
      final notifier = _TestNotifier();
      var errorCalled = false;

      await notifier.toggle(
        action: () async => throw Exception('실패'),
        onError: () => errorCalled = true,
      );

      expect(notifier.value, isFalse);
      expect(errorCalled, isTrue);
    });
  });
}
