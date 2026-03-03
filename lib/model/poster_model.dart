//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PosterModel with ChangeNotifier {
  //final FutureBuilder<QuerySnapshot<Object?>> collectionPoster;

  final int id;
  final String title;
  final String description;
  final String location;
  final String startDate;
  final String endDate;
  final String posterUrl;

  PosterModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.location,
      required this.startDate,
      required this.endDate,
      required this.posterUrl,
      }
      );

  factory PosterModel.fromJson(Map<String, dynamic> json) {
    return PosterModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      posterUrl: json['posterUrl'],
    );
  }
}
