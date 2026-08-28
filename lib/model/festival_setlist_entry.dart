import 'package:feple/model/song_model.dart';

import 'json_reader.dart';
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
      artistFestivalId: json.integer('artistFestivalId'),
      artistId: json.integer('artistId'),
      artistName: json.str('artistName'),
      artistNameEn: json.str('artistNameEn'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
      songs: json.objectList('songs').map(SongModel.fromJson).toList(),
    );
  }
}
