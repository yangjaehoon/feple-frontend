import 'date_format.dart';
import 'localized_text.dart';

enum CertStatus {
  approved('APPROVED'),
  pending('PENDING'),
  rejected('REJECTED');

  const CertStatus(this.value);
  final String value;

  static CertStatus fromValue(String? value) => CertStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => CertStatus.pending,
      );
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
        id: (json['id'] as num?)?.toInt() ?? 0,
        festivalId: (json['festivalId'] as num?)?.toInt() ?? 0,
        status: CertStatus.fromValue(json['status'] as String?),
        festivalTitle: json['festivalTitle'] as String? ?? '',
        festivalTitleEn: json['festivalTitleEn'] as String? ?? '',
        posterUrl: json['festivalPosterUrl'] as String? ?? json['photoUrl'] as String?,
        rejectionMessage: json['rejectionMessage'] as String?,
        createdAt: json['createdAt'] as String?,
        myRating: (json['rating'] as num?)?.toInt(),
        myReview: json['userReview'] as String?,
      );

  String displayFestivalTitle(bool isEnglish) =>
      pickLocalized(isEnglish, festivalTitle, festivalTitleEn);

  String? get formattedDate => formatShortDate(createdAt);
}
