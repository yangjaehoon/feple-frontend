import 'package:feple/injection.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationCountable extends Mock implements NotificationCountable {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockNotificationCountable mockService;
  late NotificationCountNotifier notifier;

  setUp(() {
    mockService = MockNotificationCountable();
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    sl.registerSingleton<NotificationCountable>(mockService);
    notifier = NotificationCountNotifier();
  });

  tearDown(() {
    notifier.dispose();
    sl.unregister<NotificationCountable>();
  });

  test('초기 count는 0', () {
    expect(notifier.count, 0);
  });

  group('load', () {
    test('서비스에서 count를 가져와 반영', () async {
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 5);

      await notifier.load();

      expect(notifier.count, 5);
    });

    test('여러 번 load 시 최신 값으로 갱신', () async {
      when(() => mockService.getUnreadCount())
          .thenAnswer((_) async => 3);
      await notifier.load();
      expect(notifier.count, 3);

      when(() => mockService.getUnreadCount())
          .thenAnswer((_) async => 7);
      await notifier.load();
      expect(notifier.count, 7);
    });

    test('서비스 예외 시 count 변경 없음 (크래시 없음)', () async {
      when(() => mockService.getUnreadCount()).thenThrow(Exception('network'));

      await expectLater(notifier.load(), completes);

      expect(notifier.count, 0);
    });
  });

  group('clear', () {
    test('count를 0으로 초기화', () async {
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 10);
      await notifier.load();
      expect(notifier.count, 10);

      notifier.clear();

      expect(notifier.count, 0);
    });

    test('load 없이 clear 호출해도 안전', () {
      notifier.clear();
      expect(notifier.count, 0);
    });
  });
}
