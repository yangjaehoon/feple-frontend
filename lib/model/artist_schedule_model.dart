enum EventType {
  festival,
  fanMeeting,
  tvShow;

  static EventType fromString(String? value) {
    switch (value) {
      case 'FAN_MEETING':
        return EventType.fanMeeting;
      case 'TV_SHOW':
        return EventType.tvShow;
      case 'FESTIVAL':
      default:
        return EventType.festival;
    }
  }
}

class ArtistScheduleModel {
  final int festivalId;
  final String title;
  final String? description;
  final String? location;
  final String? startDate;
  final String? endDate;
  final String? posterUrl;
  final EventType eventType;
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

  bool get isPast {
    final dateStr = endDate ?? startDate;
    if (dateStr == null) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  String get dateRange {
    final start = startDate;
    if (start == null) return '';
    final end = endDate;
    return (end != null && end != start) ? '$start ~ $end' : start;
  }

  factory ArtistScheduleModel.fromJson(Map<String, dynamic> json) {
    return ArtistScheduleModel(
      festivalId: (json['festivalId'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      posterUrl: json['posterUrl'] as String?,
      eventType: EventType.fromString(json['eventType'] as String?),
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
  final String artistNameEn;
  final String? profileImageUrl;

  const CoArtistInfo({
    required this.artistId,
    required this.artistName,
    this.artistNameEn = '',
    this.profileImageUrl,
  });

  String displayName(bool isEnglish) =>
      isEnglish && artistNameEn.isNotEmpty ? artistNameEn : artistName;

  factory CoArtistInfo.fromJson(Map<String, dynamic> json) {
    return CoArtistInfo(
      artistId: (json['artistId'] as num).toInt(),
      artistName: json['artistName'] as String,
      artistNameEn: json['artistNameEn'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
