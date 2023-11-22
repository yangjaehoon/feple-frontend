import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PosterModel with ChangeNotifier{
  //final FutureBuilder<QuerySnapshot<Object?>> collectionPoster;
  final String date;
  final String id;
  final String imgUrl;
  final String location;
  final String name;

  PosterModel(
      { required this.date, required this.id, required this.imgUrl, required this.location, required this.name });
}