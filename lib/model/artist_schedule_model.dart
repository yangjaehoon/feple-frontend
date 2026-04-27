class ArtistScheduleModel {
  final int festivalId;
  final String title;
  final String? description;
  final String? location;
  final String? startDate;
  final String? endDate;
  final String? posterUrl;
  final String eventType; // FESTIVAL, FAN_MEETING, TV_SHOW
  final List<CoArtistInfo> coArtists;

  const ArtistScheduleModel({
    required this.festivalId,
    required this.title,
    this.description,
    this.location,
    this.startDate,
    this.endDate,
    this.posterUrl,
    required this.eventType,
    required this.coArtists,
  });

  factory ArtistScheduleModel.fromJson(Map<String, dynamic> json) {
    return ArtistScheduleModel(
      festivalId: json['festivalId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      posterUrl: json['posterUrl'] as String?,
      eventType: json['eventType'] as String? ?? 'FESTIVAL',
      coArtists: (json['coArtists'] as List<dynamic>?)
              ?.map((e) => CoArtistInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CoArtistInfo {
  final int artistId;
  final String artistName;
  final String? profileImageUrl;

  const CoArtistInfo({
    required this.artistId,
    required this.artistName,
    this.profileImageUrl,
  });

  factory CoArtistInfo.fromJson(Map<String, dynamic> json) {
    return CoArtistInfo(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
