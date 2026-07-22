import 'package:feple/injection.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/model/notification_page.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/screen/notification/notification_notifier.dart';
import 'package:feple/service/notification_feedable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationFeedable extends Mock implements NotificationFeedable {}

NotificationModel _item(int id, {bool read = false, NotificationType? type}) =>
    NotificationModel(
      id: id,
      type: type ?? NotificationType.newComment,
      title: 'title $id',
      body: 'body $id',
      read: read,
    );

NotificationPage _page(List<NotificationModel> items, {bool hasMore = false}) =>
    NotificationPage(items: items, hasMore: hasMore);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockNotificationFeedable mockService;
  late NotificationNotifier notifier;

  setUpAll(() {
    registerFallbackValue(NotificationFilter.all);
  });

  setUp(() {
    mockService = MockNotificationFeedable();
    if (sl.isRegistered<NotificationFeedable>()) {
      sl.unregister<NotificationFeedable>();
    }
    sl.registerSingleton<NotificationFeedable>(mockService);
    notifier = NotificationNotifier();
  });

  tearDown(() {
    notifier.dispose();
    sl.unregister<NotificationFeedable>();
  });

  group('load', () {
    test('성공 시 items 채움, isLoading=false, hasError=false', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1), _item(2)]));

      await notifier.load();

      expect(notifier.items.length, 2);
      expect(notifier.isLoading, false);
      expect(notifier.hasError, false);
    });

    test('실패 시 hasError=true, isLoading=false', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenThrow(Exception('network'));

      await notifier.load();

      expect(notifier.hasError, true);
      expect(notifier.isLoading, false);
      expect(notifier.items, isEmpty);
    });

    test('load 재호출 시 이전 items 초기화 후 새 데이터 반영', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1)]));
      await notifier.load();

      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(2), _item(3)]));
      await notifier.load();

      expect(notifier.items.map((n) => n.id).toList(), [2, 3]);
    });

    test('hasMore=true이면 loadMore 가능', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1)], hasMore: true));

      await notifier.load();

      when(() => mockService.fetchPage(1, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(2)], hasMore: false));
      await notifier.loadMore();

      expect(notifier.items.length, 2);
    });
  });

  group('refresh', () {
    test('items가 비어 있으면 force=false여도 fetch', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1)]));

      await notifier.refresh();

      expect(notifier.items.length, 1);
    });

    test('3분 이내 로드된 items가 있으면 force=false 시 스킵', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1)]));
      await notifier.load();

      // 추가 fetch 없이 통과해야 함
      await notifier.refresh(force: false);

      verify(() => mockService.fetchPage(0, filter: any(named: 'filter'))).called(1);
    });

    test('force=true이면 stale 여부 무관하게 fetch', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1)]));
      await notifier.load();

      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(2)]));
      await notifier.refresh(force: true);

      expect(notifier.items.first.id, 2);
    });
  });

  group('loadMore', () {
    setUp(() async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1)], hasMore: true));
      await notifier.load();
    });

    test('페이지를 누적해서 추가', () async {
      when(() => mockService.fetchPage(1, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(2)], hasMore: false));

      await notifier.loadMore();

      expect(notifier.items.map((n) => n.id).toList(), [1, 2]);
    });

    test('isLoadingMore 중 재호출 무시', () async {
      when(() => mockService.fetchPage(1, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(2)]));

      final f1 = notifier.loadMore();
      final f2 = notifier.loadMore();
      await Future.wait([f1, f2]);

      verify(() => mockService.fetchPage(1, filter: any(named: 'filter'))).called(1);
    });

    test('hasMore=false이면 loadMore 호출 무시', () async {
      when(() => mockService.fetchPage(1, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([], hasMore: false));
      await notifier.loadMore();

      await notifier.loadMore();

      verify(() => mockService.fetchPage(1, filter: any(named: 'filter'))).called(1);
    });
  });

  group('setFilter', () {
    test('filter 변경 시 load 재호출', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([]));
      await notifier.load();

      notifier.setFilter(NotificationFilter.comment);
      await Future.delayed(Duration.zero); // load() 완료 대기

      verify(() => mockService.fetchPage(0, filter: any(named: 'filter'))).called(2);
      expect(notifier.filter, NotificationFilter.comment);
    });

    test('동일 filter 재설정 시 load 안 함', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([]));
      await notifier.load();

      notifier.setFilter(NotificationFilter.all);

      verify(() => mockService.fetchPage(0, filter: any(named: 'filter'))).called(1);
    });
  });

  group('markRead', () {
    setUp(() async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, read: false)]));
      await notifier.load();
    });

    test('읽지 않은 알림 markRead 시 read=true로 낙관적 업데이트', () async {
      when(() => mockService.markRead(1)).thenAnswer((_) async {});

      await notifier.markRead(notifier.items.first);

      expect(notifier.items.first.read, true);
    });

    test('이미 read인 알림은 서비스 호출 안 함', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, read: true)]));
      await notifier.load();

      await notifier.markRead(notifier.items.first);

      verifyNever(() => mockService.markRead(any()));
    });
  });

  group('markAllRead', () {
    test('미읽음 알림이 있으면 모두 read=true로 업데이트', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1), _item(2, read: true)]));
      await notifier.load();
      when(() => mockService.markAllRead()).thenAnswer((_) async {});

      await notifier.markAllRead();

      expect(notifier.items.every((n) => n.read), true);
    });

    test('모두 이미 read이면 서비스 호출 안 함', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async =>
              _page([_item(1, read: true), _item(2, read: true)]));
      await notifier.load();

      await notifier.markAllRead();

      verifyNever(() => mockService.markAllRead());
    });
  });

  group('hasUnread', () {
    test('미읽음 알림이 있으면 true', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, read: false)]));
      await notifier.load();
      expect(notifier.hasUnread, true);
    });

    test('모두 읽음이면 false', () async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, read: true)]));
      await notifier.load();
      expect(notifier.hasUnread, false);
    });
  });

  group('removeLocally / undoDismiss', () {
    late NotificationModel item1;

    setUp(() async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1), _item(2), _item(3)]));
      await notifier.load();
      item1 = notifier.items.first;
    });

    test('removeLocally 시 해당 알림이 목록에서 제거됨', () {
      notifier.removeLocally(item1);
      expect(notifier.items.any((n) => n.id == 1), false);
    });

    test('undoDismiss 시 원래 인덱스에 복원됨', () {
      notifier.removeLocally(item1);
      notifier.undoDismiss(item1);

      expect(notifier.items.first.id, 1);
    });

    test('이미 목록에 있는 알림은 undoDismiss 무시', () {
      notifier.undoDismiss(item1);
      // 중복 삽입 없어야 함
      expect(notifier.items.where((n) => n.id == 1).length, 1);
    });

    test('savedIndex가 목록 범위 초과 시 index=0에 삽입', () {
      // 3개 중 마지막 (index=2)를 remove 후 앞 2개도 제거하면 savedIndex가 범위 초과
      final item3 = notifier.items.last;
      notifier.removeLocally(item3); // savedIndex=2
      notifier.removeLocally(notifier.items.last); // index 1
      notifier.removeLocally(notifier.items.last); // index 0

      notifier.undoDismiss(item3); // savedIndex=2, 하지만 목록이 비어있으므로 index=0
      expect(notifier.items.first.id, 3);
    });
  });

  group('confirmDismiss', () {
    setUp(() async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1), _item(2)]));
      await notifier.load();
    });

    test('일반 알림은 서비스 delete 호출', () async {
      when(() => mockService.delete(1)).thenAnswer((_) async {});
      final item = notifier.items.first;
      notifier.removeLocally(item);

      await notifier.confirmDismiss(item);

      verify(() => mockService.delete(1)).called(1);
    });

    test('adminBroadcast 타입도 서비스 delete 호출 — UI에서 스와이프 자체를 막으므로 도달 시 동일하게 삭제', () async {
      final broadcastItem =
          _item(99, type: NotificationType.adminBroadcast);
      when(() => mockService.delete(99)).thenAnswer((_) async {});
      notifier.removeLocally(broadcastItem);

      await notifier.confirmDismiss(broadcastItem);

      verify(() => mockService.delete(99)).called(1);
    });
  });

  group('NotificationType.isDismissible', () {
    test('adminBroadcast는 false, 그 외 타입은 true', () {
      expect(NotificationType.adminBroadcast.isDismissible, isFalse);
      expect(NotificationType.newComment.isDismissible, isTrue);
    });
  });

  group('전체 삭제 (removeAllLocally/undoDeleteAll/confirmDeleteAll)', () {
    setUp(() async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1), _item(2)]));
      await notifier.load();
    });

    test('removeAllLocally 시 목록이 즉시 비워짐', () {
      notifier.removeAllLocally();
      expect(notifier.items, isEmpty);
    });

    test('confirmDeleteAll 시에만 서비스 deleteAll 호출', () async {
      when(() => mockService.deleteAll()).thenAnswer((_) async {});
      notifier.removeAllLocally();

      await notifier.confirmDeleteAll();

      verify(() => mockService.deleteAll()).called(1);
    });

    test('undoDeleteAll 시 원래 목록으로 복원되고 서비스는 호출 안 됨', () {
      notifier.removeAllLocally();

      notifier.undoDeleteAll();

      expect(notifier.items.map((n) => n.id), [1, 2]);
      verifyNever(() => mockService.deleteAll());
    });
  });
}
