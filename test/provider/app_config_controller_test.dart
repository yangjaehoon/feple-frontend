import 'dart:async';

import 'package:feple/model/app_config_model.dart';
import 'package:feple/provider/app_config_controller.dart';
import 'package:feple/service/app_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockAppConfigService extends Mock implements AppConfigService {}

AppConfigModel _config({
  String minSupportedVersion = '1.0.0',
  String latestVersion = '1.0.0',
  bool maintenance = false,
  String? maintenanceMessage,
  String? noticeMessage,
}) =>
    AppConfigModel(
      minSupportedVersion: minSupportedVersion,
      latestVersion: latestVersion,
      maintenance: maintenance,
      maintenanceMessage: maintenanceMessage,
      noticeMessage: noticeMessage,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppConfigService mockService;
  late AppConfigController controller;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Feple',
      packageName: 'com.dobino.feple',
      version: '1.2.0',
      buildNumber: '1',
      buildSignature: '',
    );
    mockService = MockAppConfigService();
    controller = AppConfigController(mockService);
  });

  tearDown(() => controller.dispose());

  test('조회에 성공하면 설정과 현재 버전을 채우고 통지한다', () async {
    when(() => mockService.fetch())
        .thenAnswer((_) async => _config(noticeMessage: '공지'));
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.load();

    expect(controller.config, isNotNull);
    expect(controller.noticeMessage, '공지');
    expect(controller.currentVersion, '1.2.0');
    expect(notified, 1);
  });

  // 네트워크 장애로 사용자가 앱에 못 들어가는 편이 공지를 놓치는 것보다 나쁘다.
  test('설정 조회가 실패해도 던지지 않고 아무 게이트도 걸지 않는다', () async {
    when(() => mockService.fetch()).thenThrow(Exception('network'));

    await expectLater(controller.load(), completes);

    expect(controller.config, isNull);
    expect(controller.isUnderMaintenance, isFalse);
    expect(controller.requiresForceUpdate, isFalse);
  });

  test('점검 중이면 isUnderMaintenance가 true이고 문구를 그대로 넘긴다', () async {
    when(() => mockService.fetch()).thenAnswer(
        (_) async => _config(maintenance: true, maintenanceMessage: '점검 중'));

    await controller.load();

    expect(controller.isUnderMaintenance, isTrue);
    expect(controller.maintenanceMessage, '점검 중');
  });

  test('현재 버전이 최소 지원 버전 미만이면 강제 업데이트 대상', () async {
    when(() => mockService.fetch())
        .thenAnswer((_) async => _config(minSupportedVersion: '9.9.9'));

    await controller.load();

    expect(controller.requiresForceUpdate, isTrue);
  });

  // 버전을 제대로 못 읽었다고 사용자를 막으면 안 된다(fail-open).
  test('버전 문자열이 비정상이면 강제 업데이트로 막지 않는다', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Feple',
      packageName: 'com.dobino.feple',
      version: '',
      buildNumber: '1',
      buildSignature: '',
    );
    when(() => mockService.fetch())
        .thenAnswer((_) async => _config(minSupportedVersion: '9.9.9'));

    await controller.load();

    // 형식 오류는 isVersionBelow가 fail-open으로 처리한다.
    expect(controller.requiresForceUpdate, isFalse);
  });

  // 설정 조회와 버전 조회는 서로 독립적이어야 한다 — 한쪽이 실패했다고
  // 다른 쪽까지 버리면, 설정을 못 받은 사용자에게 권장 업데이트 안내도
  // 영영 못 띄우게 된다.
  test('설정 조회가 실패해도 현재 버전은 채운다', () async {
    when(() => mockService.fetch()).thenThrow(Exception('network'));

    await controller.load();

    expect(controller.config, isNull);
    expect(controller.currentVersion, '1.2.0');
  });

  group('reload', () {
    test('점검이 해제되면 최신 설정으로 갈아끼운다', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => _config(maintenance: true));
      await controller.load();
      expect(controller.isUnderMaintenance, isTrue);

      when(() => mockService.fetch())
          .thenAnswer((_) async => _config(maintenance: false));
      await controller.reload();

      expect(controller.isUnderMaintenance, isFalse);
    });

    // 늦게 출발한 응답이 먼저 와서 앱에 진입한 뒤 먼저 출발한 낡은 응답이
    // 도착하면 점검 화면으로 다시 튕긴다.
    test('진행 중이면 재조회 요청을 무시한다', () async {
      final gate = Completer<AppConfigModel>();
      when(() => mockService.fetch()).thenAnswer((_) => gate.future);

      final first = controller.reload();
      final second = controller.reload();
      gate.complete(_config(maintenance: true));
      await Future.wait([first, second]);

      verify(() => mockService.fetch()).called(1);
    });

    test('앞선 재조회가 끝난 뒤에는 다시 요청한다', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => _config());

      await controller.reload();
      await controller.reload();

      verify(() => mockService.fetch()).called(2);
    });

    // null로 덮어쓰면 점검 중인 서버로 사용자를 들여보내게 된다.
    test('재조회가 실패하면 직전 설정을 유지한다', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => _config(maintenance: true));
      await controller.load();

      when(() => mockService.fetch()).thenThrow(Exception('network'));
      await expectLater(controller.reload(), completes);

      expect(controller.isUnderMaintenance, isTrue,
          reason: '재조회 실패로 게이트가 풀리면 안 된다');
    });
  });
}
