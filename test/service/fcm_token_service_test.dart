import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/fcm_token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void drainRequests(MockWebServer server) {
  while (true) {
    try {
      server.takeRequest();
    } catch (_) {
      break;
    }
  }
}

void main() {
  final server = MockWebServer();
  late MockFirebaseMessaging messaging;
  late FcmTokenService service;

  // flutter_secure_storage 목: read('accessToken')만 이 값을 돌려준다
  String? storedJwt;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'read' && call.arguments['key'] == 'accessToken') {
          return storedJwt;
        }
        return null;
      },
    );
    HttpOverrides.global = null;
    await server.start();
    DioClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  setUp(() {
    ApiCacheStore.clearForTesting();
    storedJwt = null;
    messaging = MockFirebaseMessaging();
    service = FcmTokenService(messaging);
  });

  tearDown(() => drainRequests(server));

  tearDownAll(() => server.shutdown());

  // 호스트 플랫폼(Platform.isIOS == false)에서 항상 android로 전송됨
  const expectedPlatform = 'android';

  group('FcmTokenService.register', () {
    test('토큰을 받아 서버에 등록한다', () async {
      when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-1');
      server.enqueue(httpCode: 200);

      await service.register(language: 'en');

      final request = server.takeRequest();
      expect(request.uri.path, '/users/device-token');
      expect(request.method, 'POST');
      expect(request.body, contains('"token":"fcm-token-1"'));
      expect(request.body, contains('"language":"en"'));
      expect(request.body, contains('"platform":"$expectedPlatform"'));
    });

    test('토큰이 null이면 서버 호출을 하지 않는다', () async {
      when(() => messaging.getToken()).thenAnswer((_) async => null);

      await service.register();

      expect(() => server.takeRequest(), throwsException);
    });

    test('language 미지정 시 기본값 ko로 전송한다', () async {
      when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-2');
      server.enqueue(httpCode: 200);

      await service.register();

      expect(server.takeRequest().body, contains('"language":"ko"'));
    });
  });

  group('FcmTokenService.sendToServer', () {
    test('토큰과 언어를 payload로 전송한다', () async {
      server.enqueue(httpCode: 200);

      await service.sendToServer('raw-token', language: 'en');

      final request = server.takeRequest();
      expect(request.body, contains('"token":"raw-token"'));
      expect(request.body, contains('"language":"en"'));
    });
  });

  group('FcmTokenService.unregister', () {
    test('JWT가 없으면 아무 요청도 하지 않는다', () async {
      storedJwt = null;

      await service.unregister();

      verifyNever(() => messaging.getToken());
      expect(() => server.takeRequest(), throwsException);
    });

    test('JWT가 있으면 현재 토큰으로 서버에서 삭제한다', () async {
      storedJwt = 'jwt-abc';
      when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-3');
      server.enqueue(httpCode: 200);

      await service.unregister();

      final request = server.takeRequest();
      expect(request.uri.path, '/users/device-token');
      expect(request.method, 'DELETE');
      expect(request.body, contains('"token":"fcm-token-3"'));
    });

    test('JWT는 있지만 FCM 토큰이 null이면 삭제 요청을 하지 않는다', () async {
      storedJwt = 'jwt-abc';
      when(() => messaging.getToken()).thenAnswer((_) async => null);

      await service.unregister();

      expect(() => server.takeRequest(), throwsException);
    });
  });
}
