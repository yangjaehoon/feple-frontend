import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/exception/age_restricted_exception.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/auth/auth_token_exchanger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final server = MockWebServer();
  final exchanger = AuthTokenExchanger();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      // read는 액세스 토큰이 있는 것처럼 응답한다 — submitBirthDate가 토큰을 읽어 헤더에 싣는다.
      (call) async => call.method == 'read' ? 'stored-access-token' : null,
    );
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await server.start();
    DioClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  tearDownAll(() => server.shutdown());

  group('AuthTokenExchanger.exchangeFirebaseToken', () {
    test('성공하면 토큰을 저장하고 AppUser를 반환한다', () async {
      server.enqueue(
        body:
            '{"accessToken":"access1","refreshToken":"refresh1","user":{"id":1,"nickname":"tester1"}}',
        headers: {'Content-Type': 'application/json'},
      );

      final user = await exchanger.exchangeFirebaseToken('id-token');

      expect(user.id, 1);
      expect(user.nickname, 'tester1');
    });

    test('서버 오류 응답이면 auth_err_auth_failed 예외를 던진다', () async {
      server.enqueue(httpCode: 401, body: '{"message":"invalid"}');

      await expectLater(
        exchanger.exchangeFirebaseToken('bad-token'),
        throwsA(isA<Exception>()),
      );
    });

    test('403 AGE_RESTRICTED면 AgeRestrictedException을 던진다 (만 14세 미만 계정 재로그인)', () async {
      server.enqueue(
        httpCode: 403,
        body: '{"code":"AGE_RESTRICTED","message":"restricted"}',
        headers: {'Content-Type': 'application/json'},
      );

      await expectLater(
        exchanger.exchangeFirebaseToken('restricted-token'),
        throwsA(isA<AgeRestrictedException>()),
      );
    });
  });

  group('AuthTokenExchanger.exchangeKakaoToken', () {
    test('성공하면 AppUser를 반환한다', () async {
      server.enqueue(
        body: '{"accessToken":"access2","user":{"id":2,"nickname":"tester2"}}',
        headers: {'Content-Type': 'application/json'},
      );

      final user = await exchanger.exchangeKakaoToken('kakao-access-token');

      expect(user.id, 2);
      expect(user.nickname, 'tester2');
    });
  });

  group('AuthTokenExchanger.submitBirthDate', () {
    test('204면 정상 완료된다', () async {
      server.enqueue(httpCode: 204);

      await expectLater(
        exchanger.submitBirthDate(DateTime(2000, 1, 1)),
        completes,
      );
    });

    test('403 AGE_RESTRICTED면 AgeRestrictedException을 던진다', () async {
      server.enqueue(
        httpCode: 403,
        body: '{"code":"AGE_RESTRICTED","message":"restricted"}',
        headers: {'Content-Type': 'application/json'},
      );

      await expectLater(
        exchanger.submitBirthDate(DateTime(2015, 1, 1)),
        throwsA(isA<AgeRestrictedException>()),
      );
    });

    test('그 외 오류는 AuthExchangeException(Exception)을 던진다', () async {
      server.enqueue(httpCode: 500);

      await expectLater(
        exchanger.submitBirthDate(DateTime(2000, 1, 1)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthTokenExchanger.revokeRefreshToken', () {
    test('실패해도 예외를 던지지 않는다', () async {
      server.enqueue(httpCode: 500);

      await expectLater(exchanger.revokeRefreshToken('refresh-token'), completes);
    });
  });
}
