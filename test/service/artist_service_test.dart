import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/artist_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = ArtistService();

  const artistJson = '{"id":1,"name":"Band","nameEn":"Band",'
      '"genre":"ROCK","profileImageUrl":"https://img.example.com/a.jpg",'
      '"followerCount":10}';

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

  group('ArtistService.fetchArtistById', () {
    test('단일 아티스트를 파싱한다', () async {
      server.enqueue(
        body: artistJson,
        headers: {'Content-Type': 'application/json'},
      );

      final artist = await service.fetchArtistById(1);

      expect(artist.id, 1);
      expect(artist.name, 'Band');
      expect(artist.genre, 'ROCK');
    });
  });

  group('ArtistService.fetchArtists', () {
    test('아티스트 목록을 파싱한다', () async {
      server.enqueue(
        body: '[$artistJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final artists = await service.fetchArtists();

      expect(artists, hasLength(1));
      expect(artists.first.id, 1);
    });

    test('List가 아닌 응답이면 빈 목록을 반환한다', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchArtists(), isEmpty);
    });
  });

  group('ArtistService.fetchRelatedArtists', () {
    test('연관 아티스트 목록을 파싱한다', () async {
      server.enqueue(
        body: '[$artistJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final artists = await service.fetchRelatedArtists(1);

      expect(artists, hasLength(1));
    });
  });
}
