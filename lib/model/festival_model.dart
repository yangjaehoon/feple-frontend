//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FestivalModel with ChangeNotifier {
  //final FutureBuilder<QuerySnapshot<Object?>> collectionPoster;

  final int id;
  final String title;
  final String? titleEn;
  final String description;
  final String location;
  final String startDate;
  final String endDate;
  final String posterUrl;
  final double? latitude;
  final double? longitude;

  String localizedTitle(String languageCode) =>
      languageCode == 'en' && titleEn != null && titleEn!.isNotEmpty
          ? titleEn!
          : title;

  FestivalModel(
      {required this.id,
      required this.title,
      this.titleEn,
      required this.description,
      required this.location,
      required this.startDate,
      required this.endDate,
      required this.posterUrl,
      this.latitude,
      this.longitude,
      });

  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    return FestivalModel(
      id: json['id'],
      title: json['title'],
      titleEn: json['titleEn'] as String?,
      description: json['description'],
      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      posterUrl: json['posterUrl'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
