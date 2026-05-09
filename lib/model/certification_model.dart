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
  final int festivalId;
  final CertStatus status;
  final String festivalTitle;
  final String? posterUrl;
  final String? rejectionMessage;
  final String? createdAt;

  const CertificationModel({
    required this.festivalId,
    required this.status,
    required this.festivalTitle,
    this.posterUrl,
    this.rejectionMessage,
    this.createdAt,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) =>
      CertificationModel(
        festivalId: (json['festivalId'] as num?)?.toInt() ?? 0,
        status: CertStatus.fromValue(json['status'] as String?),
        festivalTitle: json['festivalTitle'] as String? ?? '',
        posterUrl: json['festivalPosterUrl'] as String? ?? json['photoUrl'] as String?,
        rejectionMessage: json['rejectionMessage'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  String? get formattedDate {
    if (createdAt == null) return null;
    return createdAt!.length >= 10 ? createdAt!.substring(0, 10) : createdAt;
  }
}
