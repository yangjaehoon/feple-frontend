import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/user_service.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = UserService();

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

  group('UserService', () {
    // ── fetchUser ──────────────────────────────────────────────────────────

    test('fetchUser parses User from JSON map', () async {
      server.enqueue(
        body: '{"id":1,"nickname":"user1","level":"BRONZE"}',
        headers: {'Content-Type': 'application/json'},
      );

      final user = await service.fetchUser(1);

      expect(user.id, 1);
      expect(user.nickname, 'user1');
      expect(user.level, 'BRONZE');
    });

    test('fetchUser throws FormatException on unexpected response type', () async {
      server.enqueue(
        body: '"just a string"',
        headers: {'Content-Type': 'application/json'},
      );

      await expectLater(service.fetchUser(1), throwsA(isA<FormatException>()));
    });

    // ── fetchFollowingArtists ──────────────────────────────────────────────

    test('fetchFollowingArtists parses artist list', () async {
      server.enqueue(
        body: '[{"id":10,"name":"IU","nameEn":"IU","followerCount":5000}]',
        headers: {'Content-Type': 'application/json'},
      );

      final artists = await service.fetchFollowingArtists(1);

      expect(artists.length, 1);
      expect(artists.first.id, 10);
      expect(artists.first.name, 'IU');
      expect(artists.first.followerCount, 5000);
    });

    test('fetchFollowingArtists returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      final artists = await service.fetchFollowingArtists(1);

      expect(artists, isEmpty);
    });

    // ── fetchLikedFestivals ────────────────────────────────────────────────

    test('fetchLikedFestivals parses festival list', () async {
      server.enqueue(
        body: '[{"id":5,"title":"Rock Fest","titleEn":"Rock Fest"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final festivals = await service.fetchLikedFestivals(1);

      expect(festivals.length, 1);
      expect(festivals.first.id, 5);
      expect(festivals.first.title, 'Rock Fest');
    });

    // ── updateNickname ─────────────────────────────────────────────────────

    test('updateNickname completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.updateNickname(1, 'newnick'), completes);
    });

    // ── updateBio ──────────────────────────────────────────────────────────

    test('updateBio completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.updateBio(1, 'hello'), completes);
    });

    test('updateBio throws BannedWordException on BAD_WORD 400', () async {
      server.enqueue(
        httpCode: 400,
        body: '{"code":"BAD_WORD","field":"bio"}',
        headers: {'Content-Type': 'application/json'},
      );

      await expectLater(
        service.updateBio(1, 'banned'),
        throwsA(isA<BannedWordException>()),
      );
    });

    // ── checkNicknameAvailability ──────────────────────────────────────────

    test('checkNicknameAvailability returns available=true', () async {
      server.enqueue(
        body: '{"available":true,"code":"OK"}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.checkNicknameAvailability('newname');

      expect(result.available, true);
      expect(result.code, 'OK');
    });

    test('checkNicknameAvailability returns available=false on duplicate', () async {
      server.enqueue(
        body: '{"available":false,"code":"DUPLICATE"}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.checkNicknameAvailability('takenname');

      expect(result.available, false);
      expect(result.code, 'DUPLICATE');
    });

    test('deleteUser completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.deleteUser(1), completes);
    });
  });
}
