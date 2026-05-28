import 'package:flutter/material.dart';

class FestivalModel with ChangeNotifier {
  final int id;
  final String title;
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

  bool get isEnded {
    if (endDate.isEmpty) return false;
    try {
      final end = DateTime.parse(endDate);
      return end.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    } catch (_) {
      return false;
    }
  }

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

  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    return FestivalModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      posterUrl: json['posterUrl'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ageRestriction: json['ageRestriction'] as String?,
      attendingCount: (json['attendingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
