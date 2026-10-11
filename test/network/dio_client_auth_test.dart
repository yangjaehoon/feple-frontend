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
    DioClient.onUserBanned = null;
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

  test('갱신 요청이 429면 세션을 유지한다 (IP 단위 요청 한도는 토큰 만료가 아님)', () async {
    server.enqueue(httpCode: 401);
    server.enqueue(httpCode: 429); // /auth/refresh — 요청 한도 초과
    var sessionExpiredCalls = 0;
    DioClient.onSessionExpired = () async => sessionExpiredCalls++;

    await expectLater(
      DioClient.dio.get('/protected-d'),
      throwsA(isA<DioException>()),
    );

    expect(sessionExpiredCalls, 0);
    expect(secureStore['refreshToken'], 'valid-refresh');
  });

  test('세션 만료 뒤 새 세션이 시작되면 다시 토큰을 갱신한다', () async {
    // 1) 첫 세션 만료
    server.enqueue(httpCode: 401);
    server.enqueue(httpCode: 401); // /auth/refresh — 거부
    DioClient.onSessionExpired = () async {};
    await expectLater(
      DioClient.dio.get('/protected-e'),
      throwsA(isA<DioException>()),
    );

    // 2) 재로그인 — 새 토큰 저장 + 가드 해제
    secureStore
      ..['accessToken'] = 'relogin-access'
      ..['refreshToken'] = 'relogin-refresh';
    DioClient.markSessionStarted();

    // 3) 새 세션의 액세스 토큰 만료 → 갱신 후 재시도돼야 한다
    server.enqueue(httpCode: 401);
    server.enqueue(
      body: '{"accessToken":"new-access","refreshToken":"new-refresh"}',
      headers: jsonHeaders(),
    );
    server.enqueue(body: '{"ok":true}', headers: jsonHeaders());

    final res = await DioClient.dio.get('/protected-f');

    expect(res.data['ok'], true);
    expect(secureStore['accessToken'], 'new-access');
  });

  test('403 USER_BANNED면 onUserBanned를 호출한다', () async {
    server.enqueue(
      httpCode: 403,
      body: '{"code":"USER_BANNED","error":"Forbidden"}',
      headers: jsonHeaders(),
    );
    var bannedCalls = 0;
    DioClient.onUserBanned = () async => bannedCalls++;

    await expectLater(
      DioClient.dio.get('/protected-g'),
      throwsA(isA<DioException>()),
    );

    expect(bannedCalls, 1);
  });

  test('갱신 요청이 403 USER_BANNED면 만료 대신 정지 안내로 끝낸다', () async {
    server.enqueue(httpCode: 401);
    server.enqueue(
      httpCode: 403,
      body: '{"code":"USER_BANNED"}',
      headers: jsonHeaders(),
    ); // /auth/refresh — 정지 계정
    var sessionExpiredCalls = 0;
    var bannedCalls = 0;
    DioClient.onSessionExpired = () async => sessionExpiredCalls++;
    DioClient.onUserBanned = () async => bannedCalls++;

    await expectLater(
      DioClient.dio.get('/protected-h'),
      throwsA(isA<DioException>()),
    );

    expect(bannedCalls, 1);
    expect(sessionExpiredCalls, 0);
    expect(secureStore['refreshToken'], isNull);
  });
}
