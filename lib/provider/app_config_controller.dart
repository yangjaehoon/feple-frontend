import 'dart:developer';

import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/util/app_version.dart';
import 'package:feple/model/app_config_model.dart';
import 'package:feple/service/app_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 콜드스타트에 조회하는 앱 전역 설정(`GET /app/config`)과 현재 앱 버전을 들고,
/// 점검·강제 업데이트 여부를 판단한다.
///
/// 조회는 **절대 예외를 던지지 않는다** — 설정을 못 받으면 아무 게이트도 걸지
/// 않고 정상 진입시킨다. 네트워크 장애로 사용자가 앱에 못 들어가는 편이
/// 점검 안내를 놓치는 것보다 나쁘다.
class AppConfigController extends SafeChangeNotifier {
  AppConfigController(this._service);

  final AppConfigService _service;

  AppConfigModel? _config;
  String? _currentVersion;
  bool _isReloading = false;

  /// 조회 실패 시 null. 권장 업데이트 안내처럼 모델 전체가 필요한 곳에서 쓴다.
  AppConfigModel? get config => _config;

  /// 현재 앱 버전("1.2.0", 빌드 번호 없음). 조회 실패 시 null.
  String? get currentVersion => _currentVersion;

  /// 점검 중이면 점검 안내 화면만 노출한다.
  bool get isUnderMaintenance => _config?.maintenance ?? false;

  String? get maintenanceMessage => _config?.maintenanceMessage;

  /// 앱 상단 공지 배너 문구. null이면 미노출.
  String? get noticeMessage => _config?.noticeMessage;

  /// 이 버전 미만 클라이언트는 강제 업데이트 대상.
  /// 버전을 못 읽었으면 막지 않는다(fail-open).
  bool get requiresForceUpdate {
    final config = _config;
    final version = _currentVersion;
    if (config == null || version == null) return false;
    return isVersionBelow(version, config.minSupportedVersion);
  }

  /// 콜드스타트 1회 조회. 설정과 버전은 서로 독립적이라 병렬로 기다린다 —
  /// 둘 다 스플래시를 붙잡으므로 순차로 더하면 그만큼 진입이 늦어진다.
  /// 버전 조회가 실패해도 (점검 판단엔 버전이 필요 없으므로) 점검 게이트는
  /// 그대로 동작해야 하므로 각각 따로 처리한다.
  Future<void> load() async {
    final (config, version) = await (_fetchConfig(), _readCurrentVersion()).wait;
    if (config != null) _config = config;
    if (version != null) _currentVersion = version;
    safeNotify();
  }

  /// 점검 화면의 "다시 시도" — 설정만 다시 조회한다(버전은 런타임에 안 바뀜).
  /// 실패하면 직전 설정을 유지한다 — null로 덮어써 게이트가 풀리면 점검 중인
  /// 서버로 사용자를 들여보내게 된다.
  ///
  /// 진행 중이면 무시한다. 버튼을 연타해 요청이 겹치면 **도착 순서대로**
  /// 덮어쓰게 되는데, 늦게 출발한 응답이 먼저 와서 앱에 진입한 뒤 먼저
  /// 출발한 낡은 응답이 도착하면 점검 화면으로 다시 튕긴다.
  Future<void> reload() async {
    if (_isReloading) return;
    _isReloading = true;
    try {
      final config = await _fetchConfig();
      if (config == null) return;
      _config = config;
      safeNotify();
    } finally {
      _isReloading = false;
    }
  }

  Future<AppConfigModel?> _fetchConfig() async {
    try {
      return await _service.fetch().timeout(const Duration(seconds: 6));
    } catch (e) {
      log('App config load failed (ignored): $e');
      return null;
    }
  }

  Future<String?> _readCurrentVersion() async {
    try {
      final info =
          await PackageInfo.fromPlatform().timeout(const Duration(seconds: 6));
      return info.version;
    } catch (e) {
      log('App version lookup failed (ignored): $e');
      return null;
    }
  }
}
