import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/home/home_state_notifier.dart';
import 'package:feple/service/cache_prefetch_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserService extends Mock implements UserService {}
class MockFestivalCacheService extends Mock implements FestivalCacheService {}
class MockCachePrefetchService extends Mock implements CachePrefetchService {}

void main() {
  late HomeStateNotifier notifier;

  setUp(() {
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    if (sl.isRegistered<FestivalCacheService>()) sl.unregister<FestivalCacheService>();
    if (sl.isRegistered<CachePrefetchService>()) sl.unregister<CachePrefetchService>();

    sl.registerSingleton<UserService>(MockUserService());
    sl.registerSingleton<FestivalCacheService>(MockFestivalCacheService());
    sl.registerSingleton<CachePrefetchService>(MockCachePrefetchService());

    notifier = HomeStateNotifier();
  });

  tearDown(() {
    sl.unregister<UserService>();
    sl.unregister<FestivalCacheService>();
    sl.unregister<CachePrefetchService>();
  });

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
