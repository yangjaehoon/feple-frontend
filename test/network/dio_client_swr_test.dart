import 'dart:io';

import 'package:dio/dio.dart';
import 'package:feple/common/util/forced_refresh.dart';
import 'package:feple/common/util/request_scope.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

/// SWR 캐시가 실제로 GET을 단축하는지, 그리고 withForcedRefresh가 그 단축을
/// 우회해 실제 네트워크로 나가는지 — Dio 인터셉터까지 통과하는 통합 검증.
/// (server.requestCount는 서버 수명 동안 누적되므로 델타로 검증한다)
void main() {
  final server = MockWebServer();

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

  Map<String, String> jsonHeaders() => {'Content-Type': 'application/json'};

  test('두 번째 GET은 캐시로 단축된다 (서버 미도달)', () async {
    server.enqueue(body: '{"v":1}', headers: jsonHeaders());
    final before = server.requestCount;

    final first = await DioClient.dio.get('/swr-a');
    expect(first.data['v'], 1);
    expect(server.requestCount - before, 1);

    // 큐가 비었지만 캐시 단축이라 hang하지 않고 즉시 반환
    final second = await DioClient.dio.get('/swr-a');
    expect(second.data['v'], 1);
    expect(server.requestCount - before, 1); // 서버 미도달
  });

  test('withForcedRefresh는 캐시를 건너뛰고 실제 요청을 보낸다', () async {
    server.enqueue(body: '{"v":1}', headers: jsonHeaders());
    final before = server.requestCount;
    await DioClient.dio.get('/swr-b'); // 캐시 채움

    server.enqueue(body: '{"v":2}', headers: jsonHeaders());
    final forced = await withForcedRefresh(() => DioClient.dio.get('/swr-b'));

    expect(forced.data['v'], 2); // 캐시(1)가 아니라 새 응답(2)
    expect(server.requestCount - before, 2);
  });

  test('per-request extra.refresh 플래그도 캐시를 건너뛴다', () async {
    server.enqueue(body: '{"v":1}', headers: jsonHeaders());
    final before = server.requestCount;
    await DioClient.dio.get('/swr-c');

    server.enqueue(body: '{"v":9}', headers: jsonHeaders());
    final forced = await DioClient.dio.get(
      '/swr-c',
      options: Options(extra: {'refresh': true}),
    );

    expect(forced.data['v'], 9);
    expect(server.requestCount - before, 2);
  });

  test('withCancelScope의 취소된 토큰이 인터셉터를 통해 요청에 부착된다', () async {
    final token = CancelToken()..cancel('disposed');

    await expectLater(
      withCancelScope(token, () => DioClient.dio.get('/swr-d')),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
  });
}
