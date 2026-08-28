import 'date_format.dart';
import 'json_reader.dart';

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
      id: json.integer('id'),
      songTitle: json.str('songTitle'),
      youtubeUrl: json.strOrNull('youtubeUrl'),
      status: _parseStatus(json.strOrNull('status')),
      createdAt: json.strOrNull('createdAt'),
      artistId: json.intOrNull('artistId'),
      artistName: json.strOrNull('artistName'),
      artistNameEn: json.str('artistNameEn'),
    );
  }

  // 알 수 없는/누락된 값은 pending으로 폴백 (가장 보수적인 상태).
  static SongRequestStatus _parseStatus(String? raw) => switch (raw) {
    'PENDING' => SongRequestStatus.pending,
    'APPROVED' => SongRequestStatus.approved,
    'REJECTED' => SongRequestStatus.rejected,
    _ => SongRequestStatus.pending,
  };
}
