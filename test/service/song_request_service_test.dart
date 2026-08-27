import 'dart:io';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/song_request_service.dart';
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
  final service = SongRequestService();

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

  group('SongRequestService.submit', () {
    test('youtubeUrl 없이 제출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submit(artistId: 1, songTitle: '노래 제목');

      final request = server.takeRequest();
      expect(request.uri.path, '/artists/1/song-requests');
      expect(request.body, contains('"songTitle":"노래 제목"'));
      expect(request.body, isNot(contains('youtubeUrl')));
    });

    test('youtubeUrl과 함께 제출한다', () async {
      server.enqueue(httpCode: 200);

      await service.submit(
        artistId: 1,
        songTitle: '노래 제목',
        youtubeUrl: 'https://youtu.be/abc',
      );

      expect(
        server.takeRequest().body,
        contains('"youtubeUrl":"https://youtu.be/abc"'),
      );
    });
  });

  group('SongRequestService.fetchAllMyRequests', () {
    test('내 신청 목록을 파싱한다', () async {
      server.enqueue(
        body: '[{"id":1,"songTitle":"Song","status":"APPROVED",'
            '"artistId":3,"artistName":"Singer"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final requests = await service.fetchAllMyRequests(9);

      expect(requests, hasLength(1));
      expect(requests.first.status, SongRequestStatus.approved);
      expect(requests.first.isApproved, true);
    });

    test('빈 목록을 반환한다', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchAllMyRequests(9), isEmpty);
    });
  });
}
