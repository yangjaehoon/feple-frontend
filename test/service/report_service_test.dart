import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/report_service.dart';
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
  final service = ReportService();

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

  group('ReportService', () {
    test('submitReport는 reason을 대문자로 전송한다', () async {
      server.enqueue(httpCode: 200);

      await service.submitReport(1, ReportReason.spam);

      final request = server.takeRequest();
      expect(request.uri.path, '/posts/1/report');
      expect(request.body, contains('"reason":"SPAM"'));
      expect(request.body, isNot(contains('detail')));
    });

    test('detail이 있으면 payload에 포함한다', () async {
      server.enqueue(httpCode: 200);

      await service.submitReport(1, ReportReason.abuse, detail: '욕설');

      final request = server.takeRequest();
      expect(request.body, contains('"detail":"욕설"'));
    });

    test('submitCommentReport는 comment 엔드포인트를 호출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submitCommentReport(5, ReportReason.obscene);

      expect(server.takeRequest().uri.path, '/comments/5/report');
    });

    test('submitPhotoReport는 photo 엔드포인트를 호출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submitPhotoReport(3, 9, ReportReason.other);

      expect(server.takeRequest().uri.path, '/artists/3/photos/9/report');
    });

    test('submitUserReport는 user 엔드포인트를 호출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submitUserReport(7, ReportReason.misinformation);

      expect(server.takeRequest().uri.path, '/users/7/report');
    });
  });
}
