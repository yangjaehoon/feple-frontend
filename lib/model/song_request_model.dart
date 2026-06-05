class SongRequestModel {
  final int id;
  final String songTitle;
  final String? youtubeUrl;
  final String status;
  final String? createdAt;
  final int? artistId;
  final String? artistName;

  const SongRequestModel({
    required this.id,
    required this.songTitle,
    this.youtubeUrl,
    required this.status,
    this.createdAt,
    this.artistId,
    this.artistName,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  String? get formattedDate {
    if (createdAt == null) return null;
    try {
      final dt = DateTime.parse(createdAt!);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt;
    }
  }

  factory SongRequestModel.fromJson(Map<String, dynamic> json) {
    return SongRequestModel(
      id: (json['id'] as num).toInt(),
      songTitle: json['songTitle'] as String,
      youtubeUrl: json['youtubeUrl'] as String?,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String?,
      artistId: json['artistId'] as int?,
      artistName: json['artistName'] as String?,
    );
  }
}
