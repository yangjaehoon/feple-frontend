import 'date_format.dart';

enum SongRequestStatus { pending, approved, rejected }

class SongRequestModel {
  final int id;
  final String songTitle;
  final String? youtubeUrl;
  final SongRequestStatus status;
  final String? createdAt;
  final int? artistId;
  final String? artistName;
  final String artistNameEn;

  const SongRequestModel({
    required this.id,
    required this.songTitle,
    this.youtubeUrl,
    required this.status,
    this.createdAt,
    this.artistId,
    this.artistName,
    this.artistNameEn = '',
  });

  String? displayArtistName(bool isEnglish) {
    if (isEnglish && artistNameEn.isNotEmpty) return artistNameEn;
    return artistName;
  }

  bool get isPending => status == SongRequestStatus.pending;
  bool get isApproved => status == SongRequestStatus.approved;
  bool get isRejected => status == SongRequestStatus.rejected;

  String? get formattedDate => formatShortDate(createdAt);

  factory SongRequestModel.fromJson(Map<String, dynamic> json) {
    return SongRequestModel(
      id: (json['id'] as num).toInt(),
      songTitle: json['songTitle'] as String,
      youtubeUrl: json['youtubeUrl'] as String?,
      status: _parseStatus(json['status'] as String),
      createdAt: json['createdAt'] as String?,
      artistId: json['artistId'] as int?,
      artistName: json['artistName'] as String?,
      artistNameEn: json['artistNameEn'] as String? ?? '',
    );
  }

  static SongRequestStatus _parseStatus(String raw) => switch (raw) {
    'APPROVED' => SongRequestStatus.approved,
    'REJECTED' => SongRequestStatus.rejected,
    _          => SongRequestStatus.pending,
  };
}
