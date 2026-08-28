import 'package:feple/common/util/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delay 경과 후 마지막 action만 1회 실행한다', () async {
    final debouncer = Debouncer(const Duration(milliseconds: 60));
    var calls = 0;
    var lastValue = 0;

    debouncer.run(() {
      calls++;
      lastValue = 1;
    });
    await Future.delayed(const Duration(milliseconds: 20));
    debouncer.run(() {
      calls++;
      lastValue = 2;
    });
    await Future.delayed(const Duration(milliseconds: 20));
    debouncer.run(() {
      calls++;
      lastValue = 3;
    });

    expect(calls, 0, reason: 'delay 전에는 실행되지 않는다');
    await Future.delayed(const Duration(milliseconds: 100));
    expect(calls, 1);
    expect(lastValue, 3);
  });

  test('cancel 하면 대기 중이던 action이 실행되지 않는다', () async {
    final debouncer = Debouncer(const Duration(milliseconds: 40));
    var called = false;

    debouncer.run(() => called = true);
    debouncer.cancel();
    await Future.delayed(const Duration(milliseconds: 80));

    expect(called, isFalse);
    expect(debouncer.isPending, isFalse);
  });

  test('dispose 후에는 대기 중인 실행이 없다', () async {
    final debouncer = Debouncer(const Duration(milliseconds: 40));
    debouncer.run(() {});
    debouncer.dispose();

    expect(debouncer.isPending, isFalse);
    await Future.delayed(const Duration(milliseconds: 80));
    expect(debouncer.isPending, isFalse);
  });
}
