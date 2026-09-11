import 'dart:io';

import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/app_config_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = AppConfigService();

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

  // mock_web_server가 응답 본문을 latin1로 write하므로 본문은 ASCII만 사용한다.
  // (한글 파싱 검증은 app_config_model_test.dart에서 jsonDecode로 커버.)

  test('앱 설정을 파싱한다', () async {
    server.enqueue(
      body: '{"minSupportedVersion":"1.2.0","latestVersion":"1.3.0",'
          '"maintenance":false,"maintenanceMessage":null}',
      headers: {'Content-Type': 'application/json'},
    );

    final config = await service.fetch();

    expect(config.minSupportedVersion, '1.2.0');
    expect(config.latestVersion, '1.3.0');
    expect(config.maintenance, isFalse);
    expect(config.maintenanceMessage, isNull);
  });

  test('점검 모드 응답을 파싱한다', () async {
    server.enqueue(
      body: '{"minSupportedVersion":"0.0.0","latestVersion":"0.0.0",'
          '"maintenance":true,"maintenanceMessage":"Under maintenance","features":{}}',
      headers: {'Content-Type': 'application/json'},
    );

    final config = await service.fetch();

    expect(config.maintenance, isTrue);
    expect(config.maintenanceMessage, 'Under maintenance');
  });
}
