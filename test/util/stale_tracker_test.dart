import 'package:feple/common/stale_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaleTracker', () {
    test('한 번도 로드하지 않았으면 stale이다', () {
      final tracker = StaleTracker(const Duration(minutes: 5));

      expect(tracker.isStale, isTrue);
    });

    test('markLoaded 직후에는 stale이 아니다', () {
      final tracker = StaleTracker(const Duration(minutes: 5));

      tracker.markLoaded();

      expect(tracker.isStale, isFalse);
    });

    test('staleAfter 시간이 지나면 다시 stale이 된다', () async {
      final tracker = StaleTracker(const Duration(milliseconds: 1));

      tracker.markLoaded();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(tracker.isStale, isTrue);
    });
  });
}
