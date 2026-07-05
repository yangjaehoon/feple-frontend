import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/notification_service.dart';
import 'package:feple/service/notification_feedable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = NotificationService();

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

  group('NotificationService', () {
    // ── fetchPage ──────────────────────────────────────────────────────────

    test('fetchPage parses notification list', () async {
      server.enqueue(
        body: '{"content":[{"id":1,"type":"COMMENT","title":"Comment","body":"body",'
            '"titleEn":"Comment","bodyEn":"body","read":false}],'
            '"page":{"number":0,"totalPages":1}}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPage(0);

      expect(page.items.length, 1);
      expect(page.items.first.id, 1);
      expect(page.items.first.read, false);
    });

    test('fetchPage hasMore true when not on last page', () async {
      server.enqueue(
        body: '{"content":[],"page":{"number":0,"totalPages":3}}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPage(0);

      expect(page.hasMore, true);
    });

    test('fetchPage hasMore false on last page', () async {
      server.enqueue(
        body: '{"content":[],"page":{"number":2,"totalPages":3}}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPage(2);

      expect(page.hasMore, false);
    });

    test('fetchPage with cert filter completes normally', () async {
      server.enqueue(
        body: '{"content":[],"page":{"number":0,"totalPages":1}}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPage(0, filter: NotifFilter.cert);

      expect(page.items, isEmpty);
      expect(page.hasMore, false);
    });

    test('fetchPage with comment filter completes normally', () async {
      server.enqueue(
        body: '{"content":[],"page":{"number":0,"totalPages":2}}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPage(0, filter: NotifFilter.comment);

      expect(page.hasMore, true);
    });

    test('fetchPage handles missing page field gracefully', () async {
      server.enqueue(
        body: '{"content":[]}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPage(0);

      expect(page.hasMore, false);
      expect(page.items, isEmpty);
    });

    // ── getUnreadCount ─────────────────────────────────────────────────────

    test('getUnreadCount returns count', () async {
      server.enqueue(
        body: '{"count":7}',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.getUnreadCount(), 7);
    });

    test('getUnreadCount returns 0 when count is null', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.getUnreadCount(), 0);
    });

    // ── markRead / markAllRead ─────────────────────────────────────────────

    test('markRead completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.markRead(1), completes);
    });

    test('markAllRead completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.markAllRead(), completes);
    });

    // ── delete / deleteAll ─────────────────────────────────────────────────

    test('delete completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.delete(1), completes);
    });

    test('deleteAll completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.deleteAll(), completes);
    });
  });
}
