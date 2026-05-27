class FestivalPreview {
  final int id;
  final String title;
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

  const FestivalPreview({
    required this.id,
    required this.title,
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
  });

  /// 오늘 기준 D-day. 음수 = 진행중, 0 = 오늘 시작, 양수 = N일 후. null = 날짜 파싱 불가 또는 종료됨
  int? get dDaysUntil {
    if (isEnded || startDate.isEmpty) return null;
    try {
      final start = DateTime.parse(startDate);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final startDay = DateTime(start.year, start.month, start.day);
      return startDay.difference(todayDate).inDays;
    } catch (_) {
      return null;
    }
  }

  bool get isEnded {
    if (endDate == null || endDate!.isEmpty) return false;
    try {
      final end = DateTime.parse(endDate!);
      return end.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    } catch (_) {
      return false;
    }
  }

  factory FestivalPreview.fromJson(Map<String, dynamic> json) {
    return FestivalPreview(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
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
    );
  }
}