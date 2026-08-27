import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = ArtistFollowService(userService: UserService());

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

  group('ArtistFollowService.follow / unfollow', () {
    test('follow는 예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.follow(1), completes);
    });

    test('unfollow는 예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.unfollow(1), completes);
    });
  });

  group('ArtistFollowService.getFollowStatus', () {
    test('팔로우 상태를 파싱한다', () async {
      server.enqueue(
        body: '{"followed":true,"followerCount":42}',
        headers: {'Content-Type': 'application/json'},
      );

      final status = await service.getFollowStatus(1);

      expect(status.followed, true);
      expect(status.followerCount, 42);
    });
  });

  group('ArtistFollowService.fetchFollowingIds', () {
    test('팔로잉 아티스트 id 집합을 반환한다', () async {
      server.enqueue(
        body: '[{"id":1,"name":"A"},{"id":2,"name":"B"},{"id":1,"name":"A"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final ids = await service.fetchFollowingIds(7);

      expect(ids, {1, 2});
    });
  });

  group('ArtistFollowService.fetchFollowedArtistNames', () {
    test('빈 이름을 제외한 아티스트 이름 집합을 반환한다', () async {
      server.enqueue(
        body: '[{"id":1,"name":"A"},{"id":2,"name":""},{"id":3,"name":"C"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final names = await service.fetchFollowedArtistNames(7);

      expect(names, {'A', 'C'});
    });
  });
}
