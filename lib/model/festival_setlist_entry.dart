import 'package:feple/model/song_model.dart';

import 'localized_text.dart';

class FestivalSetlistEntry {
  final int artistFestivalId;
  final int artistId;
  final String artistName;
  final String artistNameEn;
  final String? profileImageUrl;
  final List<SongModel> songs;

  const FestivalSetlistEntry({
    required this.artistFestivalId,
    required this.artistId,
    required this.artistName,
    this.artistNameEn = '',
    this.profileImageUrl,
    required this.songs,
  });

  String displayName(bool isEnglish) => pickLocalized(isEnglish, artistName, artistNameEn);

  Set<int> get songIds => songs.map((s) => s.id).toSet();

  Map<String, dynamic> toJson() => {
        'artistFestivalId': artistFestivalId,
        'artistId': artistId,
        'artistName': artistName,
        'artistNameEn': artistNameEn,
        'profileImageUrl': profileImageUrl,
        'songs': songs.map((s) => s.toJson()).toList(),
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
    );
  }
}
