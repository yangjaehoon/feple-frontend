import 'dart:io';
import 'package:feple/model/notification_preference_model.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/notification_preference_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

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
  final service = NotificationPreferenceService();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null,
    );
    HttpOverrides.global = null;
    await server.start();
    DioClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  setUp(() => ApiCacheStore.clearForTesting());

  tearDown(() => drainRequests(server));

  tearDownAll(() => server.shutdown());

  group('NotificationPreferenceService.getPreferences', () {
    test('알림 설정을 파싱한다', () async {
      server.enqueue(
        body: '{"certEnabled":false,"commentEnabled":true,'
            '"festivalEnabled":false,"songRequestEnabled":true,'
            '"quietHoursEnabled":true}',
        headers: {'Content-Type': 'application/json'},
      );

      final prefs = await service.getPreferences();

      expect(prefs.certEnabled, false);
      expect(prefs.festivalEnabled, false);
      expect(prefs.quietHoursEnabled, true);
    });

    test('필드 누락 시 기본값을 사용한다', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      final prefs = await service.getPreferences();

      expect(prefs.certEnabled, true);
      expect(prefs.quietHoursEnabled, false);
    });
  });

  group('NotificationPreferenceService.updatePreferences', () {
    test('모든 토글 값을 전송한다', () async {
      server.enqueue(httpCode: 200);

      const prefs = NotificationPreferenceModel(
        certEnabled: true,
        commentEnabled: false,
        festivalEnabled: true,
        songRequestEnabled: false,
        quietHoursEnabled: true,
      );

      await service.updatePreferences(prefs);

      final body = server.takeRequest().body!;
      expect(body, contains('"certEnabled":true'));
      expect(body, contains('"commentEnabled":false'));
      expect(body, contains('"songRequestEnabled":false'));
      expect(body, contains('"quietHoursEnabled":true'));
    });
  });
}
