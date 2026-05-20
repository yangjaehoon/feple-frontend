import 'package:feple/screen/main/tab/home/home_state_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HomeStateNotifier notifier;

  setUp(() {
    notifier = HomeStateNotifier();
  });

  // applyOrder는 sl에 접근하지 않는 순수 메서드이므로 DI 설정 불필요
  group('HomeStateNotifier.applyOrder', () {
    int id(int item) => item;

    test('order 비어있으면 원래 순서 그대로 반환', () {
      final result = notifier.applyOrder([1, 2, 3], [], id);
      expect(result, [1, 2, 3]);
    });

    test('order가 전체 항목 포함 시 order 순으로 재배열', () {
      final result = notifier.applyOrder([1, 2, 3], [3, 1, 2], id);
      expect(result, [3, 1, 2]);
    });

    test('order가 일부 항목만 포함 시 order 항목 앞, 나머지 원래 순서대로 뒤에 추가', () {
      final result = notifier.applyOrder([1, 2, 3], [3], id);
      expect(result, [3, 1, 2]);
    });

    test('order에 items에 없는 ID 포함 시 해당 ID 스킵', () {
      final result = notifier.applyOrder([1, 2], [5, 1], id);
      expect(result, [1, 2]);
    });

    test('빈 items이면 빈 리스트 반환', () {
      final result = notifier.applyOrder(<int>[], [1, 2, 3], id);
      expect(result, isEmpty);
    });

    test('중복 없이 order 항목이 한 번씩만 나타남', () {
      final result = notifier.applyOrder([1, 2, 3], [2, 3], id);
      expect(result, [2, 3, 1]);
      expect(result.length, 3);
    });
  });
}
