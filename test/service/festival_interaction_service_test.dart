import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = FestivalInteractionService();

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

  tearDownAll(() => server.shutdown());

  group('FestivalInteractionService', () {
    test('isLiked returns true', () async {
      server.enqueue(
        body: 'true',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isLiked(1), true);
    });

    test('isLiked returns false', () async {
      server.enqueue(
        body: 'false',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isLiked(1), false);
    });

    test('isAttending returns true', () async {
      server.enqueue(
        body: 'true',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isAttending(1), true);
    });

    test('isAttending returns false', () async {
      server.enqueue(
        body: 'false',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isAttending(1), false);
    });

    test('toggleLike completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.toggleLike(1), completes);
    });

    test('toggleAttending completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.toggleAttending(1), completes);
    });
  });
}
