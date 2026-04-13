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
  });

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
    );
  }
}