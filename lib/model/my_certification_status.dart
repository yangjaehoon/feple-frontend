import 'package:feple/model/certification_model.dart';

/// 특정 페스티벌에 대한 내 인증 상태 + 내가 남긴 별점/후기 (API 응답 매핑용).
/// UI 표시용 3단계 상태는 [CertState] 참조 — 이 클래스와 다른 개념이다.
class MyCertificationStatus {
  final CertStatus? status;
  final int? certId;
  final int? myRating;
  final String? myReview;

  const MyCertificationStatus({this.status, this.certId, this.myRating, this.myReview});

  static const none = MyCertificationStatus();

  factory MyCertificationStatus.fromJson(Map<String, dynamic> json) {
    final state = json['certState'] as String?;
    if (state == null || state == 'NONE') return MyCertificationStatus.none;
    return MyCertificationStatus(
      status: CertStatus.fromValue(state),
      certId: (json['certId'] as num?)?.toInt(),
      myRating: (json['myRating'] as num?)?.toInt(),
      myReview: json['myReview'] as String?,
    );
  }
}
