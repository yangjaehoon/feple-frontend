import 'package:feple/screen/notification/fcm_navigation_handler.dart';
import 'package:feple/service/fcm_notification_handler.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:feple/service/fcm_token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFcmNavigationHandler extends Mock implements FcmNavigationHandler {}

class MockFcmTokenService extends Mock implements FcmTokenService {}

class MockFcmNotificationHandler extends Mock implements FcmNotificationHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFcmTokenService tokenService;
  late FcmService service;

  setUp(() {
    tokenService = MockFcmTokenService();
    when(() => tokenService.unregister()).thenAnswer((_) async {});
    service = FcmService(
      messaging: MockFirebaseMessaging(),
      navHandler: MockFcmNavigationHandler(),
      tokenService: tokenService,
      notifHandler: MockFcmNotificationHandler(),
    );
  });

  group('FcmService.stop', () {
    test('서버 토큰 등록을 해제한다', () async {
      await service.stop();

      verify(() => tokenService.unregister()).called(1);
    });

    test('_setup 없이 호출해도 예외 없이 완료된다 (구독이 null)', () async {
      await expectLater(service.stop(), completes);
    });

    test('여러 번 호출해도 안전하다', () async {
      await service.stop();
      await service.stop();

      verify(() => tokenService.unregister()).called(2);
    });
  });
}
