import 'dart:async';

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

    // 여러 탭의 앱바가 같은 프레임에 붙거나, 로그인 전이 보정과 새로 뜬 탭의
    // 앱바가 겹치면 같은 조회가 동시에 두 번 나간다.
    test('진행 중인 조회가 있으면 요청을 새로 보내지 않는다', () async {
      final gate = Completer<int>();
      when(() => mockService.getUnreadCount()).thenAnswer((_) => gate.future);

      final first = notifier.load();
      final second = notifier.load();
      gate.complete(4);
      await Future.wait([first, second]);

      verify(() => mockService.getUnreadCount()).called(1);
      expect(notifier.count, 4);
    });

    test('앞선 조회가 끝난 뒤의 load는 다시 요청한다', () async {
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 1);

      await notifier.load();
      await notifier.load();

      verify(() => mockService.getUnreadCount()).called(2);
    });

    // 읽음 처리 직후의 갱신은 그 이전에 시작된 요청에 합류하면 안 된다.
    test('force는 진행 중인 조회를 기다리지 않고 새로 요청한다', () async {
      final stale = Completer<int>();
      when(() => mockService.getUnreadCount()).thenAnswer((_) => stale.future);
      final first = notifier.load();

      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 0);
      await notifier.load(force: true);
      expect(notifier.count, 0);

      // 버려진 요청이 뒤늦게 끝나도 최신 값을 덮어쓰지 않는다.
      stale.complete(9);
      await first;
      expect(notifier.count, 0);
      verify(() => mockService.getUnreadCount()).called(2);
    });

    test('조회 도중 clear되면 다음 load가 죽은 요청에 합류하지 않는다', () async {
      final stale = Completer<int>();
      when(() => mockService.getUnreadCount()).thenAnswer((_) => stale.future);
      final first = notifier.load();

      // 로그아웃 — 진행 중이던 요청의 결과는 버려진다.
      notifier.clear();

      // 같은 기기에서 바로 다시 로그인.
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 6);
      await notifier.load();

      expect(notifier.count, 6, reason: '죽은 요청에 합류하면 0으로 굳는다');
      stale.complete(9);
      await first;
      expect(notifier.count, 6);
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
