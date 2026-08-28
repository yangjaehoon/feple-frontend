import 'package:feple/common/util/festival_date_utils.dart';
import 'artist_schedule_model.dart';
import 'festival_model.dart';
import 'json_reader.dart';
import 'localized_text.dart';

class FestivalPreview {
  final int id;
  final String title;
  final String titleEn;
  final String description;
  final String location;
  final String posterUrl;
  final String startDate;
  final String? endDate;
  final List<String> genres;
  final String? region;
  final String? ageRestriction;
  final double? latitude;
  final double? longitude;
  final int attendingCount;

  const FestivalPreview({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.description = '',
    required this.location,
    required this.posterUrl,
    required this.startDate,
    this.endDate,
    this.genres = const [],
    this.region,
    this.ageRestriction,
    this.latitude,
    this.longitude,
    this.attendingCount = 0,
  });

  /// 아티스트 일정(ArtistScheduleModel)을 페스티벌 미리보기 형태로 변환.
  factory FestivalPreview.fromArtistSchedule(ArtistScheduleModel schedule) => FestivalPreview(
        id: schedule.festivalId,
        title: schedule.title,
        location: schedule.location ?? '',
        posterUrl: schedule.posterUrl ?? '',
        startDate: schedule.startDate ?? '',
        endDate: schedule.endDate,
      );

  String displayTitle(bool isEnglish) => pickLocalized(isEnglish, title, titleEn);

  bool get isEnded => isFestivalEnded(endDate);

  /// 오늘 기준 D-day. 음수 = 진행중, 0 = 오늘 시작, 양수 = N일 후. null = 날짜 파싱 불가 또는 종료됨
  int? get dDaysUntil => festivalDDaysUntil(startDate: startDate, isEnded: isEnded);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleEn': titleEn,
        'description': description,
        'location': location,
        'posterUrl': posterUrl,
        'startDate': startDate,
        'endDate': endDate,
        'genres': genres,
        'region': region,
        'ageRestriction': ageRestriction,
        'latitude': latitude,
        'longitude': longitude,
        'attendingCount': attendingCount,
      };

  FestivalModel toModel() => FestivalModel(
        id: id,
        title: title,
        titleEn: titleEn,
        description: description,
        location: location,
        startDate: startDate,
        endDate: endDate ?? '',
        posterUrl: posterUrl,
        latitude: latitude,
        longitude: longitude,
        genres: genres,
        ageRestriction: ageRestriction,
        attendingCount: attendingCount,
      );

  factory FestivalPreview.fromJson(Map<String, dynamic> json) {
    return FestivalPreview(
      id: json.integer('id'),
      title: json.str('title'),
      titleEn: json.str('titleEn'),
      description: json.str('description'),
      location: json.str('location'),
      posterUrl: json.str('posterUrl'),
      startDate: json.str('startDate'),
      endDate: json.strOrNull('endDate'),
      genres: json.stringList('genres'),
      region: json.strOrNull('region'),
      ageRestriction: json.strOrNull('ageRestriction'),
      latitude: json.dblOrNull('latitude'),
      longitude: json.dblOrNull('longitude'),
      attendingCount: json.integer('attendingCount'),
    );
  }
}
