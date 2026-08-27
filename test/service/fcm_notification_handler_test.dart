import 'package:feple/service/fcm_notification_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalNotifications extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocalNotifications plugin;
  late List<Map<String, dynamic>> tappedPayloads;
  late FcmNotificationHandler handler;

  setUp(() {
    plugin = MockLocalNotifications();
    tappedPayloads = [];
    handler = FcmNotificationHandler(
      plugin,
      onTap: (data) async => tappedPayloads.add(data),
    );
  });

  group('FcmNotificationHandler.handleForeground', () {
    test('notification 페이로드가 없으면 로컬 알림을 띄우지 않는다', () async {
      final message = RemoteMessage(data: const {'type': 'COMMENT'});

      await handler.handleForeground(message);

      verifyNever(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      );
    });
  });
}
