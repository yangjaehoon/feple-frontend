import 'json_reader.dart';

/// 앱 콜드스타트 시 `GET /app/config`로 받아오는 전역 설정.
///
/// 조회에 실패하면 이 모델 없이(null) 진행한다 — 강제 업데이트·점검 게이트를
/// 걸지 않으므로 네트워크 장애로 사용자가 앱에 못 들어가는 일이 없다.
///
/// 서버는 홈 배너 공지(`noticeMessage`)·기능 스위치(`features`)도 함께 내려주지만,
/// 그 소비는 후속 작업이라 여기서는 파싱하지 않는다.
class AppConfigModel {
  /// 이 버전 미만 클라이언트는 강제 업데이트 대상 (세맨틱 버전 "1.2.0").
  final String minSupportedVersion;

  /// 스토어 최신 버전. 이 버전 미만이면 닫을 수 있는 권장 업데이트 안내.
  final String latestVersion;

  /// 점검 모드. true면 점검 안내 화면만 노출한다.
  final bool maintenance;

  /// 점검 안내 문구. null이면 클라이언트 기본 문구를 쓴다.
  final String? maintenanceMessage;

  const AppConfigModel({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.maintenance,
    required this.maintenanceMessage,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) => AppConfigModel(
        minSupportedVersion: json.str('minSupportedVersion', '0.0.0'),
        latestVersion: json.str('latestVersion', '0.0.0'),
        maintenance: json.boolean('maintenance'),
        maintenanceMessage: _blankToNull(json.strOrNull('maintenanceMessage')),
      );

  static String? _blankToNull(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value;
}
