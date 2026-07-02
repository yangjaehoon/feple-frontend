import 'dart:io';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = ScrapService();

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

  tearDownAll(() => server.shutdown());

  group('ScrapService', () {
    test('isScraped returns true', () async {
      server.enqueue(
        body: 'true',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isScraped(1), true);
    });

    test('isScraped returns false', () async {
      server.enqueue(
        body: 'false',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isScraped(1), false);
    });

    test('toggleScrap completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.toggleScrap(1), completes);
    });

    test('fetchMyScraps parses scrap list', () async {
      server.enqueue(
        body: '[{"id":1,"title":"Post","content":"Body","likeCount":0,"nickname":"user"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final scraps = await service.fetchMyScraps();

      expect(scraps.length, 1);
      expect(scraps.first.id, 1);
    });

    test('fetchMyScraps returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      final scraps = await service.fetchMyScraps();

      expect(scraps, isEmpty);
    });
  });
}
