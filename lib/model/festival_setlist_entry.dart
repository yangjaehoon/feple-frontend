import 'package:feple/model/song_model.dart';

import 'localized_text.dart';

class FestivalSetlistEntry {
  final int artistFestivalId;
  final int artistId;
  final String artistName;
  final String artistNameEn;
  final String? profileImageUrl;
  final List<SongModel> songs;
  /// 관리자가 이 공연의 실제 셋리스트를 등록하지 않아, 아티스트가 평소 부르는 곡으로 대체 표시 중인지 여부
  final bool predicted;

  const FestivalSetlistEntry({
    required this.artistFestivalId,
    required this.artistId,
    required this.artistName,
    this.artistNameEn = '',
    this.profileImageUrl,
    required this.songs,
    this.predicted = false,
  });

  String displayName(bool isEnglish) => pickLocalized(isEnglish, artistName, artistNameEn);

  Map<String, dynamic> toJson() => {
        'artistFestivalId': artistFestivalId,
        'artistId': artistId,
        'artistName': artistName,
        'artistNameEn': artistNameEn,
        'profileImageUrl': profileImageUrl,
        'songs': songs.map((s) => s.toJson()).toList(),
        'predicted': predicted,
      };

  factory FestivalSetlistEntry.fromJson(Map<String, dynamic> json) {
    return FestivalSetlistEntry(
      artistFestivalId: (json['artistFestivalId'] as num).toInt(),
      artistId: (json['artistId'] as num).toInt(),
      artistName: json['artistName'] as String,
      artistNameEn: json['artistNameEn'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      songs: ((json['songs'] as List?) ?? [])
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      predicted: json['predicted'] as bool? ?? false,
    );
  }
}
