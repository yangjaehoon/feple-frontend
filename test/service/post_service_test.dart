import 'dart:io';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = PostService();

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

  tearDownAll(() => server.shutdown());

  group('PostService', () {
    test('unknown boardType immediately throws', () {
      expect(() => service.fetchPosts('unknown'), throwsException);
    });

    test('fetchPosts parses post list', () async {
      server.enqueue(
        body: '[{"id":1,"title":"Hello","content":"Body","likeCount":0,"nickname":"user"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final posts = await service.fetchPosts(BoardTypes.hot);

      expect(posts.length, 1);
      expect(posts.first.id, 1);
      expect(posts.first.title, 'Hello');
    });

    test('fetchPosts returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      final posts = await service.fetchPosts(BoardTypes.free);

      expect(posts, isEmpty);
    });

    test('fetchCounts parses likeCount and scrapCount record', () async {
      server.enqueue(
        body: '{"likeCount":5,"scrapCount":3}',
        headers: {'Content-Type': 'application/json'},
      );

      final counts = await service.fetchCounts(1);

      expect(counts.likeCount, 5);
      expect(counts.scrapCount, 3);
    });

    test('isLiked returns true', () async {
      server.enqueue(
        body: 'true',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isLiked(1), true);
    });

    test('isLiked returns false', () async {
      server.enqueue(
        body: 'false',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.isLiked(1), false);
    });

    test('toggleLike completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.toggleLike(1), completes);
    });
  });
}
