import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/notice_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = NoticeService();

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

  group('NoticeService.getNotices', () {
    test('공지 목록과 다음 페이지 여부를 파싱한다', () async {
      server.enqueue(
        body: '{"content":[{"id":1,"title":"Maintenance","content":"body",'
            '"pinned":true,"createdAt":"2026-01-01T00:00:00Z"}],"last":false}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.getNotices();

      expect(page.notices, hasLength(1));
      expect(page.notices.first.pinned, true);
      expect(page.hasNext, true);
    });

    test('last=true이면 hasNext는 false', () async {
      server.enqueue(
        body: '{"content":[],"last":true}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.getNotices(page: 2);

      expect(page.notices, isEmpty);
      expect(page.hasNext, false);
    });
  });

  group('NoticeService.getNotice', () {
    test('공지 상세를 파싱한다', () async {
      server.enqueue(
        body: '{"id":7,"title":"Title","content":"Detail body","pinned":false}',
        headers: {'Content-Type': 'application/json'},
      );

      final notice = await service.getNotice(7);

      expect(notice.id, 7);
      expect(notice.content, 'Detail body');
    });
  });
}
