import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/artist_suggestion_service.dart';
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
  final service = ArtistSuggestionService();

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

  group('ArtistSuggestionService.submit', () {
    test('note 없이 제출해도 예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.submit(artistName: '새 아티스트'), completes);

      final request = server.takeRequest();
      expect(request.body, contains('"artistName":"새 아티스트"'));
      expect(request.body, isNot(contains('note')));
    });

    test('note와 함께 제출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submit(artistName: '새 아티스트', note: '공연 자주 함');

      final request = server.takeRequest();
      expect(request.body, contains('"note":"공연 자주 함"'));
    });

    test('빈 note는 payload에서 제외된다', () async {
      server.enqueue(httpCode: 200);

      await service.submit(artistName: '새 아티스트', note: '');

      final request = server.takeRequest();
      expect(request.body, isNot(contains('note')));
    });
  });
}
