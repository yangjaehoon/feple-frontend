import 'dart:io';
import 'package:feple/model/search_suggestion.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/search_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = SearchService();

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

  // Artist requires genre and profileImageUrl (non-nullable String fields)
  const _artistJson =
      '{"id":1,"name":"IU","nameEn":"IU","genre":"Pop","profileImageUrl":"https://img.example.com/iu.jpg","followerCount":5000}';
  const _festivalJson =
      '{"id":5,"title":"Rock Fest","titleEn":"Rock Fest","location":"Seoul",'
      '"posterUrl":"https://img.example.com/poster.jpg","startDate":"2025-06-01"}';
  const _postJson =
      '{"id":10,"title":"Post","content":"Body","likeCount":3,"nickname":"user1"}';

  group('SearchService', () {
    // ── search ─────────────────────────────────────────────────────────────

    test('search parses artists, festivals, and posts', () async {
      server.enqueue(
        body: '{"artists":[$_artistJson],"festivals":[$_festivalJson],"posts":[$_postJson]}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.search('IU');

      expect(result.artists.length, 1);
      expect(result.artists.first.name, 'IU');
      expect(result.artists.first.followerCount, 5000);
      expect(result.festivals.length, 1);
      expect(result.festivals.first.title, 'Rock Fest');
      expect(result.posts.length, 1);
      expect(result.posts.first.id, 10);
    });

    test('search returns empty lists when keys are missing', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.search('unknown');

      expect(result.artists, isEmpty);
      expect(result.festivals, isEmpty);
      expect(result.posts, isEmpty);
    });

    test('search handles all-empty arrays', () async {
      server.enqueue(
        body: '{"artists":[],"festivals":[],"posts":[]}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.search('noresult');

      expect(result.artists, isEmpty);
      expect(result.festivals, isEmpty);
      expect(result.posts, isEmpty);
    });

    // ── suggestions ────────────────────────────────────────────────────────

    test('suggestions maps artist type to SearchType.artist', () async {
      server.enqueue(
        body: '[{"id":1,"label":"IU","labelEn":"IU","type":"artist",'
            '"imageUrl":"https://img.example.com/iu.jpg"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final suggestions = await service.suggestions('IU');

      expect(suggestions.length, 1);
      expect(suggestions.first.label, 'IU');
      expect(suggestions.first.type, SearchType.artist);
    });

    test('suggestions maps non-artist type to SearchType.festival', () async {
      server.enqueue(
        body: '[{"id":5,"label":"Rock Fest","labelEn":"Rock Fest","type":"festival","imageUrl":null}]',
        headers: {'Content-Type': 'application/json'},
      );

      final suggestions = await service.suggestions('Rock');

      expect(suggestions.length, 1);
      expect(suggestions.first.type, SearchType.festival);
      expect(suggestions.first.label, 'Rock Fest');
    });

    test('suggestions filters out items with empty label', () async {
      server.enqueue(
        body: '[{"id":1,"label":"IU","labelEn":"IU","type":"artist"},'
            '{"id":2,"label":"","labelEn":"","type":"festival"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final suggestions = await service.suggestions('I');

      expect(suggestions.length, 1);
      expect(suggestions.first.label, 'IU');
    });

    test('suggestions returns empty list when response is null', () async {
      server.enqueue(
        body: 'null',
        headers: {'Content-Type': 'application/json'},
      );

      final suggestions = await service.suggestions('x');

      expect(suggestions, isEmpty);
    });

    test('suggestions returns empty list for empty array', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      final suggestions = await service.suggestions('empty');

      expect(suggestions, isEmpty);
    });
  });
}
