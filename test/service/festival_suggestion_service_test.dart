import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_suggestion_service.dart';
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
  final service = FestivalSuggestionService();

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

  group('FestivalSuggestionService.submit', () {
    test('note 없이 제출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submit(festivalName: '새 페스티벌');

      final request = server.takeRequest();
      expect(request.uri.path, '/festival-suggestions');
      expect(request.body, contains('"festivalName":"새 페스티벌"'));
      expect(request.body, isNot(contains('note')));
    });

    test('note와 함께 제출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submit(festivalName: '새 페스티벌', note: '매년 열림');

      expect(server.takeRequest().body, contains('"note":"매년 열림"'));
    });
  });
}
