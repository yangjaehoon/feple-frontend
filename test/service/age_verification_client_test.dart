import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/exception/age_restricted_exception.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/auth/age_verification_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final server = MockWebServer();
  final client = AgeVerificationClient();

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

  group('AgeVerificationClient.submitBirthDate', () {
    test('204면 정상 완료된다', () async {
      server.enqueue(httpCode: 204);

      await expectLater(
        client.submitBirthDate(DateTime(2000, 1, 1)),
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
        client.submitBirthDate(DateTime(2015, 1, 1)),
        throwsA(isA<AgeRestrictedException>()),
      );
    });

    test('그 외 오류는 AuthExchangeException(Exception)을 던진다', () async {
      server.enqueue(httpCode: 500);

      await expectLater(
        client.submitBirthDate(DateTime(2000, 1, 1)),
        throwsA(isA<Exception>()),
      );
    });
  });
}
