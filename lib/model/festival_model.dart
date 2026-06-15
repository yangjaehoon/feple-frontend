import 'festival_date_utils.dart';

class FestivalModel {
  final int id;
  final String title;
  final String titleEn;
  final String description;
  final String location;
  final String startDate;
  final String endDate;
  final String posterUrl;
  final double? latitude;
  final double? longitude;
  final List<String> genres;
  final String? ageRestriction;
  final int attendingCount;

  FestivalModel({
    required this.id,
    required this.title,
    this.titleEn = '',
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.posterUrl,
    this.latitude,
    this.longitude,
    this.genres = const [],
    this.ageRestriction,
    this.attendingCount = 0,
  });

  String displayTitle(bool isEnglish) =>
      isEnglish && titleEn.isNotEmpty ? titleEn : title;

  bool get isEnded => isFestivalEnded(endDate);

  int? get dDaysUntil => festivalDDaysUntil(startDate: startDate, isEnded: isEnded);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleEn': titleEn,
        'description': description,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'posterUrl': posterUrl,
        'latitude': latitude,
        'longitude': longitude,
        'genres': genres,
        'ageRestriction': ageRestriction,
        'attendingCount': attendingCount,
      };

  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    return FestivalModel(
      id: json['id'] as int,
      title: json['title'] as String,
      titleEn: (json['titleEn'] as String?) ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ageRestriction: json['ageRestriction'] as String?,
      attendingCount: (json['attendingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
