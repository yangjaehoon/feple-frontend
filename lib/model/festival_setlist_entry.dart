import 'package:feple/model/song_model.dart';

class FestivalSetlistEntry {
  final int artistFestivalId;
  final int artistId;
  final String artistName;
  final String? profileImageUrl;
  final List<SongModel> songs;

  const FestivalSetlistEntry({
    required this.artistFestivalId,
    required this.artistId,
    required this.artistName,
    this.profileImageUrl,
    required this.songs,
  });

  Set<int> get songIds => songs.map((s) => s.id).toSet();

  factory FestivalSetlistEntry.fromJson(Map<String, dynamic> json) {
    return FestivalSetlistEntry(
      artistFestivalId: (json['artistFestivalId'] as num).toInt(),
      artistId: (json['artistId'] as num).toInt(),
      artistName: json['artistName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      songs: (json['songs'] as List)
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
