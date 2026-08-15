import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final server = MockWebServer();
  late FestivalDetailService service;

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiCacheStore.clearForTesting();
    service = FestivalDetailService(FestivalCacheService());
  });

  tearDownAll(() => server.shutdown());

  group('FestivalDetailService.fetchBooths', () {
    test('정상 응답이면 모든 부스를 파싱한다', () async {
      server.enqueue(
        body: '[{"id":1,"name":"Tteokbokki","boothType":"FOOD","boothTypeName":"Food",'
            '"latitude":37.5,"longitude":127.0}]',
        headers: {'Content-Type': 'application/json'},
      );

      final booths = await service.fetchBooths(1);

      expect(booths, hasLength(1));
      expect(booths.first.name, 'Tteokbokki');
    });

    test('좌표가 없는 부스는 걸러내고 나머지는 정상 파싱한다', () async {
      server.enqueue(
        body: '['
            '{"id":1,"name":"Tteokbokki","boothType":"FOOD","boothTypeName":"Food",'
            '"latitude":37.5,"longitude":127.0},'
            '{"id":2,"name":"NoCoordsBooth","boothType":"EVENT","boothTypeName":"Event"}'
            ']',
        headers: {'Content-Type': 'application/json'},
      );

      final booths = await service.fetchBooths(1);

      expect(booths, hasLength(1));
      expect(booths.first.id, 1);
    });

    test('응답이 리스트가 아니면 빈 리스트를 반환한다', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      final booths = await service.fetchBooths(1);

      expect(booths, isEmpty);
    });
  });
}
