import 'dart:io';
import 'package:feple/model/festival_diary_model.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/festival_diary_service.dart';
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
  final service = FestivalDiaryService();

  const diaryJson = '{"id":1,"festivalId":10,"festivalTitle":"Festival",'
      '"content":"had fun","visibility":"PUBLIC",'
      '"photoUrls":["https://img.example.com/1.jpg"],'
      '"createdAt":"2026-01-01T00:00:00Z","isOwner":true}';

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

  group('FestivalDiaryService.getMyDiaries', () {
    test('내 일기 목록을 파싱한다', () async {
      server.enqueue(
        body: '[$diaryJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final diaries = await service.getMyDiaries();

      expect(diaries, hasLength(1));
      expect(diaries.first.id, 1);
      expect(diaries.first.isPublic, true);
    });

    test('festivalId를 쿼리 파라미터로 전달한다', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      await service.getMyDiaries(festivalId: 42);

      expect(server.takeRequest().uri.query, contains('festivalId=42'));
    });
  });

  group('FestivalDiaryService.getDiary', () {
    test('일기 상세를 파싱한다', () async {
      server.enqueue(
        body: diaryJson,
        headers: {'Content-Type': 'application/json'},
      );

      final diary = await service.getDiary(1);

      expect(diary.festivalId, 10);
      expect(diary.photoUrls, hasLength(1));
    });
  });

  group('FestivalDiaryService.update', () {
    test('내용과 공개범위를 전송한다', () async {
      server.enqueue(httpCode: 200);

      await service.update(1, '수정된 내용', DiaryVisibility.private_);

      final body = server.takeRequest().body!;
      expect(body, contains('"content":"수정된 내용"'));
      expect(body, contains('"visibility":"PRIVATE"'));
    });
  });

  group('FestivalDiaryService.delete', () {
    test('예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.delete(1), completes);
    });
  });

  group('FestivalDiaryService.getUserPublicDiaries', () {
    test('공개 일기 페이지를 파싱한다', () async {
      server.enqueue(
        body: '{"content":[$diaryJson],"last":false}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.getUserPublicDiaries(5);

      expect(page.diaries, hasLength(1));
      expect(page.hasNext, true);
    });
  });
}
