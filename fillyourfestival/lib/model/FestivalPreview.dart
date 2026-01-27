class FestivalPreview {
  final int id;
  final String title;
  final String location;
  final String posterUrl;
  final String startDate;

  const FestivalPreview({
    required this.id,
    required this.title,
    required this.location,
    required this.posterUrl,
    required this.startDate,
  });

  factory FestivalPreview.fromJson(Map<String, dynamic> json) {
    return FestivalPreview(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      posterUrl: (json['posterUrl'] ?? '') as String,
      startDate: (json['startDate'] ?? '') as String,
    );
  }
}