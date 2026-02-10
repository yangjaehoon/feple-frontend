import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PosterModel with ChangeNotifier {
  //final FutureBuilder<QuerySnapshot<Object?>> collectionPoster;

  final String id;
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
      required this.posterUrl});
}
