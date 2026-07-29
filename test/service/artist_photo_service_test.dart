import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/artist_photo_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = ArtistPhotoService();

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

  group('ArtistPhotoService.fetchPhotos', () {
    test('사진 목록을 파싱한다', () async {
      server.enqueue(
        body: '[{"photoId":1,"url":"https://img.example.com/1.jpg",'
            '"uploaderUserId":2,"uploaderNickname":"user1",'
            '"createdAt":"2026-01-01T00:00:00Z","title":"title",'
            '"description":"desc","likeCount":0,"isLiked":false,"isAnonymous":false}]',
        headers: {'Content-Type': 'application/json'},
      );

      final photos = await service.fetchPhotos(1);

      expect(photos, hasLength(1));
      expect(photos.first.photoId, 1);
    });
  });

  group('ArtistPhotoService.toggleLike', () {
    test('예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.toggleLike(1, 1), completes);
    });
  });

  group('ArtistPhotoService.deletePhoto', () {
    test('예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.deletePhoto(1, 1), completes);
    });
  });

  group('ArtistPhotoService.updatePhoto', () {
    test('예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(
        service.updatePhoto(1, 1, '새 제목', '새 설명'),
        completes,
      );
    });
  });
}
