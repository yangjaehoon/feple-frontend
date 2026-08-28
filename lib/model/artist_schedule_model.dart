import 'date_format.dart';
import 'json_reader.dart';
import 'localized_text.dart';

enum EventType {
  festival,
  fanMeeting,
  tvShow;

  /// 알 수 없는 값이면 null. 호출부가 폴백을 정한다.
  static EventType? fromString(String? value) => switch (value) {
        'FESTIVAL' => EventType.festival,
        'FAN_MEETING' => EventType.fanMeeting,
        'TV_SHOW' => EventType.tvShow,
        _ => null,
      };
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
    final start = formatShortDate(startDate);
    if (start == null) return '';
    final end = formatShortDate(endDate);
    return (end != null && end != start) ? '$start ~ $end' : start;
  }

  factory ArtistScheduleModel.fromJson(Map<String, dynamic> json) {
    return ArtistScheduleModel(
      festivalId: json.integer('festivalId'),
      title: json.str('title'),
      description: json.strOrNull('description'),
      location: json.strOrNull('location'),
      startDate: json.strOrNull('startDate'),
      endDate: json.strOrNull('endDate'),
      posterUrl: json.strOrNull('posterUrl'),
      eventType: EventType.fromString(json.strOrNull('eventType')) ??
          EventType.festival,
      coArtists:
          json.objectList('coArtists').map(CoArtistInfo.fromJson).toList(),
    );
  }
}

/// 아티스트 일정 목록에서 반복되던 지난/예정 분류를 공용화.
extension ArtistScheduleListExtension on List<ArtistScheduleModel> {
  List<ArtistScheduleModel> get upcoming => where((e) => !e.isPast).toList();
  List<ArtistScheduleModel> get past => where((e) => e.isPast).toList();
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

  String displayName(bool isEnglish) => pickLocalized(isEnglish, artistName, artistNameEn);

  factory CoArtistInfo.fromJson(Map<String, dynamic> json) {
    return CoArtistInfo(
      artistId: json.integer('artistId'),
      artistName: json.str('artistName'),
      artistNameEn: json.str('artistNameEn'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
    );
  }
}
