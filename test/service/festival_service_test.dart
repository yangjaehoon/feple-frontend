import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final server = MockWebServer();
  final service = FestivalService(FestivalCacheService());

  const festivalJson = '{"id":1,"title":"Festival","description":"desc",'
      '"location":"Seoul","startDate":"2099-01-01","endDate":"2099-01-03",'
      '"posterUrl":"https://img.example.com/p.jpg","genres":["ROCK"]}';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
    await server.start();
    DioClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  setUp(() => ApiCacheStore.clearForTesting());

  tearDownAll(() => server.shutdown());

  group('FestivalService.fetchById', () {
    test('단일 페스티벌을 파싱한다', () async {
      server.enqueue(
        body: festivalJson,
        headers: {'Content-Type': 'application/json'},
      );

      final festival = await service.fetchById(1);

      expect(festival.id, 1);
      expect(festival.title, 'Festival');
      expect(festival.genres, ['ROCK']);
    });
  });

  group('FestivalService.fetchAll', () {
    test('페스티벌 목록을 파싱한다', () async {
      server.enqueue(
        body: '[$festivalJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final festivals = await service.fetchAll();

      expect(festivals, hasLength(1));
      expect(festivals.first.id, 1);
    });

    test('빈 목록을 반환한다', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchAll(), isEmpty);
    });
  });

  group('FestivalService.fetchPreviews', () {
    test('content와 page 메타로 hasMore를 계산한다', () async {
      server.enqueue(
        body: '{"content":[{"id":1,"title":"Festival","startDate":"2099-01-01"}],'
            '"page":{"number":0,"totalPages":3}}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPreviews(
        page: 0,
        size: 20,
        includeEnded: false,
      );

      expect(page.items, hasLength(1));
      expect(page.items.first.id, 1);
      expect(page.hasMore, true);
    });

    test('마지막 페이지면 hasMore는 false', () async {
      server.enqueue(
        body: '{"content":[],"page":{"number":2,"totalPages":3}}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPreviews(
        page: 2,
        size: 20,
        includeEnded: true,
        genres: ['ROCK'],
      );

      expect(page.items, isEmpty);
      expect(page.hasMore, false);
    });
  });
}
