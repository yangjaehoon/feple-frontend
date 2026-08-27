import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = SongService();

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

  group('SongService.fetchSongs', () {
    test('곡 목록을 파싱한다', () async {
      server.enqueue(
        body: '[{"id":1,"title":"Song","youtubeVideoId":"abc123",'
            '"festivalCount":4}]',
        headers: {'Content-Type': 'application/json'},
      );

      final songs = await service.fetchSongs(1);

      expect(songs, hasLength(1));
      expect(songs.first.title, 'Song');
      expect(songs.first.youtubeUrl,
          'https://music.youtube.com/watch?v=abc123');
    });

    test('빈 목록을 반환한다', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchSongs(1), isEmpty);
    });
  });
}
