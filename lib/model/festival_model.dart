import 'package:feple/common/util/festival_date_utils.dart';

import 'json_reader.dart';
import 'localized_text.dart';
import 'package:feple/model/festival_preview.dart';

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

  String displayTitle(bool isEnglish) => pickLocalized(isEnglish, title, titleEn);

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

  /// [FestivalPreview.toModel]의 역방향 — 상세용 모델을 목록 카드가 쓰는
  /// 미리보기 타입으로 변환한다.
  FestivalPreview toPreview() => FestivalPreview(
        id: id,
        title: title,
        titleEn: titleEn,
        description: description,
        location: location,
        posterUrl: posterUrl,
        startDate: startDate,
        endDate: endDate,
        genres: genres,
        ageRestriction: ageRestriction,
        latitude: latitude,
        longitude: longitude,
        attendingCount: attendingCount,
      );

  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    return FestivalModel(
      id: json.integer('id'),
      title: json.str('title'),
      titleEn: json.str('titleEn'),
      description: json.str('description'),
      location: json.str('location'),
      startDate: json.str('startDate'),
      endDate: json.str('endDate'),
      posterUrl: json.str('posterUrl'),
      latitude: json.dblOrNull('latitude'),
      longitude: json.dblOrNull('longitude'),
      genres: json.stringList('genres'),
      ageRestriction: json.strOrNull('ageRestriction'),
      attendingCount: json.integer('attendingCount'),
    );
  }
}
