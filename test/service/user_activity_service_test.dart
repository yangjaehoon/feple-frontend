import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = UserActivityService();

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

  const _postJson =
      '{"id":1,"title":"My Post","content":"Content","likeCount":0,"nickname":"user1"}';

  group('UserActivityService', () {
    // ── fetchPostsPage ─────────────────────────────────────────────────────

    test('fetchPostsPage parses PostCursorPage with content', () async {
      server.enqueue(
        body: '{"content":[$_postJson],"nextCursor":5,"hasNext":true}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPostsPage(1);

      expect(page.content.length, 1);
      expect(page.content.first.id, 1);
      expect(page.content.first.title, 'My Post');
      expect(page.nextCursor, 5);
      expect(page.hasNext, true);
    });

    test('fetchPostsPage hasNext false when no more pages', () async {
      server.enqueue(
        body: '{"content":[],"nextCursor":null,"hasNext":false}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.fetchPostsPage(1);

      expect(page.content, isEmpty);
      expect(page.hasNext, false);
      expect(page.nextCursor, isNull);
    });

    // ── fetchPosts ─────────────────────────────────────────────────────────

    test('fetchPosts parses Post list', () async {
      server.enqueue(
        body: '[$_postJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final posts = await service.fetchPosts(1);

      expect(posts.length, 1);
      expect(posts.first.id, 1);
      expect(posts.first.nickname, 'user1');
    });

    test('fetchPosts returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchPosts(1), isEmpty);
    });

    // ── fetchComments ──────────────────────────────────────────────────────

    test('fetchComments parses MyComment list', () async {
      server.enqueue(
        body: '[{"commentId":10,"content":"Nice","postId":1,"postTitle":"Post Title",'
            '"postContent":"Body","postNickname":"author","postLikeCount":2,'
            '"boardDisplayName":"Free"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final comments = await service.fetchComments(1);

      expect(comments.length, 1);
      expect(comments.first.commentId, 10);
      expect(comments.first.content, 'Nice');
      expect(comments.first.postId, 1);
      expect(comments.first.boardDisplayName, 'Free');
    });

    test('fetchComments returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchComments(1), isEmpty);
    });

    // ── fetchLikedPosts ────────────────────────────────────────────────────

    test('fetchLikedPosts parses Post list', () async {
      server.enqueue(
        body: '[$_postJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final posts = await service.fetchLikedPosts(1);

      expect(posts.length, 1);
      expect(posts.first.id, 1);
    });

    test('fetchLikedPosts returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.fetchLikedPosts(1), isEmpty);
    });

    // ── fetchStats ─────────────────────────────────────────────────────────

    test('fetchStats parses all UserStats fields', () async {
      server.enqueue(
        body: '{"postCount":5,"commentCount":3,"certificationCount":1,'
            '"scrapCount":2,"likedPostCount":4}',
        headers: {'Content-Type': 'application/json'},
      );

      final stats = await service.fetchStats(1);

      expect(stats.postCount, 5);
      expect(stats.commentCount, 3);
      expect(stats.certificationCount, 1);
      expect(stats.scrapCount, 2);
      expect(stats.likedPostCount, 4);
    });

    test('fetchStats uses zero defaults for missing fields', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      final stats = await service.fetchStats(1);

      expect(stats.postCount, 0);
      expect(stats.commentCount, 0);
      expect(stats.certificationCount, 0);
      expect(stats.scrapCount, 0);
      expect(stats.likedPostCount, 0);
    });
  });
}
