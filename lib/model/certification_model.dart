import 'date_format.dart';
import 'json_reader.dart';
import 'localized_text.dart';

enum CertStatus {
  approved('APPROVED'),
  pending('PENDING'),
  rejected('REJECTED');

  const CertStatus(this.value);
  final String value;

  /// 매칭되는 값이 없으면(미지의/오타 서버 값, null) null. 호출부가 폴백을 정한다.
  static CertStatus? fromValue(String? value) {
    for (final status in CertStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

class CertificationModel {
  final int id;
  final int festivalId;
  final CertStatus status;
  final String festivalTitle;
  final String festivalTitleEn;
  final String? posterUrl;
  final String? rejectionMessage;
  final String? createdAt;
  final int? myRating;
  final String? myReview;

  const CertificationModel({
    required this.id,
    required this.festivalId,
    required this.status,
    required this.festivalTitle,
    this.festivalTitleEn = '',
    this.posterUrl,
    this.rejectionMessage,
    this.createdAt,
    this.myRating,
    this.myReview,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) =>
      CertificationModel(
        id: json.integer('id'),
        festivalId: json.integer('festivalId'),
        status: CertStatus.fromValue(json.strOrNull('status')) ??
            CertStatus.pending,
        festivalTitle: json.str('festivalTitle'),
        festivalTitleEn: json.str('festivalTitleEn'),
        posterUrl: json.strOrNull('festivalPosterUrl') ?? json.strOrNull('photoUrl'),
        rejectionMessage: json.strOrNull('rejectionMessage'),
        createdAt: json.strOrNull('createdAt'),
        myRating: json.intOrNull('rating'),
        myReview: json.strOrNull('userReview'),
      );

  String displayFestivalTitle(bool isEnglish) =>
      pickLocalized(isEnglish, festivalTitle, festivalTitleEn);

  String? get formattedDate => formatShortDate(createdAt);
}
