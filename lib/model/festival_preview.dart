import 'festival_date_utils.dart';
import 'festival_model.dart';

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

  String displayTitle(bool isEnglish) =>
      isEnglish && titleEn.isNotEmpty ? titleEn : title;

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
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      titleEn: (json['titleEn'] as String?) ?? '',
      description: (json['description'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      posterUrl: (json['posterUrl'] ?? '') as String,
      startDate: (json['startDate'] ?? '') as String,
      endDate: json['endDate'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      region: json['region'] as String?,
      ageRestriction: json['ageRestriction'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      attendingCount: (json['attendingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
