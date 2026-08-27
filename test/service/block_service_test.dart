import 'dart:io';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/block_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = BlockService();

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

  group('BlockService.blockUser / unblockUser', () {
    test('blockUser는 예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.blockUser(1), completes);
    });

    test('unblockUser는 예외 없이 완료된다', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.unblockUser(1), completes);
    });
  });

  group('BlockService.getBlockedUsers', () {
    test('차단 유저 목록을 파싱한다', () async {
      server.enqueue(
        body: '[{"userId":2,"nickname":"blocked_user",'
            '"profileImageUrl":"https://img.example.com/u.jpg"}]',
        headers: {'Content-Type': 'application/json'},
      );

      final users = await service.getBlockedUsers();

      expect(users, hasLength(1));
      expect(users.first.userId, 2);
      expect(users.first.nickname, 'blocked_user');
    });

    test('빈 목록을 반환한다', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.getBlockedUsers(), isEmpty);
    });
  });
}
