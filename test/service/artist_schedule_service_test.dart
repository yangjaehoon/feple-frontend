import 'dart:io';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = ArtistScheduleService();

  const scheduleJson = '[{"festivalId":10,"title":"Summer Festival",'
      '"location":"Seoul","startDate":"2099-07-01","endDate":"2099-07-03",'
      '"posterUrl":"https://img.example.com/p.jpg","eventType":"FESTIVAL",'
      '"coArtists":[]}]';

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

  group('ArtistScheduleService.fetchSchedule', () {
    test('일정 목록을 파싱한다', () async {
      server.enqueue(
        body: scheduleJson,
        headers: {'Content-Type': 'application/json'},
      );

      final schedules = await service.fetchSchedule(1);

      expect(schedules, hasLength(1));
      expect(schedules.first.festivalId, 10);
      expect(schedules.first.eventType, EventType.festival);
    });

    test('빈 목록을 반환한다', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchSchedule(1), isEmpty);
    });
  });

  group('ArtistScheduleService.fetchFestivals', () {
    test('일정을 FestivalPreview로 변환한다', () async {
      server.enqueue(
        body: scheduleJson,
        headers: {'Content-Type': 'application/json'},
      );

      final festivals = await service.fetchFestivals(1);

      expect(festivals, hasLength(1));
      expect(festivals.first.id, 10);
      expect(festivals.first.title, 'Summer Festival');
      expect(festivals.first.location, 'Seoul');
    });
  });
}
