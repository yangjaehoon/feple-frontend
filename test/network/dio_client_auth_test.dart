import 'dart:io';

import 'package:dio/dio.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

/// 401 → 토큰 갱신 인터셉터 흐름 검증. 특히 "갱신 요청이 일시적으로 실패(5xx·
/// 타임아웃)했을 때 세션을 유지하는지" — 예전엔 모든 실패를 강제 로그아웃으로
/// 처리했다.
void main() {
  final server = MockWebServer();
  final secureStore = <String, String>{};

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args =
            (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
        switch (call.method) {
          case 'read':
            return secureStore[args['key'] as String];
          case 'write':
            secureStore[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            secureStore.remove(args['key'] as String);
            return null;
          case 'deleteAll':
            secureStore.clear();
            return null;
          case 'readAll':
            return Map<String, String>.from(secureStore);
          case 'containsKey':
            return secureStore.containsKey(args['key'] as String);
        }
        return null;
      },
    );
    HttpOverrides.global = null;
    await server.start();
    final base = 'http://127.0.0.1:${server.port}';
    DioClient.dio.options.baseUrl = base;
    DioClient.resetForTesting(plainDioBaseUrl: base);
  });

  setUp(() {
    ApiCacheStore.clearForTesting();
    DioClient.resetForTesting();
    DioClient.onSessionExpired = null;
    secureStore
      ..clear()
      ..['accessToken'] = 'old-access'
      ..['refreshToken'] = 'valid-refresh';
  });

  tearDownAll(() => server.shutdown());

  Map<String, String> jsonHeaders() => {'Content-Type': 'application/json'};

  test('갱신 요청이 5xx면 세션을 유지하고 원래 401을 전파한다', () async {
    server.enqueue(httpCode: 401); // 최초 요청
    server.enqueue(httpCode: 503); // /auth/refresh — 일시적 실패
    var sessionExpiredCalls = 0;
    DioClient.onSessionExpired = () async => sessionExpiredCalls++;

    await expectLater(
      DioClient.dio.get('/protected-a'),
      throwsA(isA<DioException>().having(
        (e) => e.response?.statusCode,
        'statusCode',
        401,
      )),
    );

    expect(sessionExpiredCalls, 0);
    expect(secureStore['refreshToken'], 'valid-refresh');
    expect(secureStore['accessToken'], 'old-access');
  });

  test('갱신 요청이 401이면 토큰을 지우고 onSessionExpired를 한 번 호출한다', () async {
    server.enqueue(httpCode: 401);
    server.enqueue(httpCode: 401); // /auth/refresh — 진짜 거부
    var sessionExpiredCalls = 0;
    DioClient.onSessionExpired = () async => sessionExpiredCalls++;

    await expectLater(
      DioClient.dio.get('/protected-b'),
      throwsA(isA<DioException>()),
    );

    expect(sessionExpiredCalls, 1);
    expect(secureStore['refreshToken'], isNull);
    expect(secureStore['accessToken'], isNull);
  });

  test('갱신 성공 시 새 토큰을 저장하고 원래 요청을 재시도한다', () async {
    server.enqueue(httpCode: 401);
    server.enqueue(
      body: '{"accessToken":"new-access","refreshToken":"new-refresh"}',
      headers: jsonHeaders(),
    );
    server.enqueue(body: '{"ok":true}', headers: jsonHeaders());

    final res = await DioClient.dio.get('/protected-c');

    expect(res.data['ok'], true);
    expect(secureStore['accessToken'], 'new-access');
    expect(secureStore['refreshToken'], 'new-refresh');
  });
}
