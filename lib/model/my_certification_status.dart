import 'package:feple/model/certification_model.dart';

import 'json_reader.dart';

/// 특정 페스티벌에 대한 내 인증 상태 + 내가 남긴 별점/후기 (API 응답 매핑용).
/// UI 표시용 3단계 상태는 [PosterCertState] 참조 — 이 클래스와 다른 개념이다.
class MyCertificationStatus {
  final CertStatus? status;
  final int? certId;
  final int? myRating;
  final String? myReview;

  const MyCertificationStatus({this.status, this.certId, this.myRating, this.myReview});

  static const none = MyCertificationStatus();

  factory MyCertificationStatus.fromJson(Map<String, dynamic> json) {
    final state = json.strOrNull('certState');
    if (state == null || state == 'NONE') return MyCertificationStatus.none;
    return MyCertificationStatus(
      status: CertStatus.fromValue(state) ?? CertStatus.pending,
      certId: json.intOrNull('certId'),
      myRating: json.intOrNull('myRating'),
      myReview: json.strOrNull('myReview'),
    );
  }
}
