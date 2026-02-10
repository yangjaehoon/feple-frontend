import 'package:dio/dio.dart';
import 'package:fast_app_base/provider/poster/get_img_url.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../model/poster_model.dart';


class PosterProvider extends ChangeNotifier {
  List<PosterModel> _posters = [];

  List<PosterModel> get posters => _posters;

  final Dio _dio = Dio();

  final String baseUrl = 'http://10.0.2.2:8080';

  PosterProvider() {
    fetchPosters();
  }

  Future<void> fetchPosters() async {
    try {
      final response = await _dio.get('$baseUrl/festivals');

      if (response.statusCode == 200) {
        final List data = response.data;

        _posters = data.map((json) => PosterModel.fromJson(json)).toList();

        notifyListeners();
        print('포스터 ${_posters.length}개 불러오기 완료');
      } else {
        print('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('포스터를 가져오는 중 오류 발생: $e');
    }
  }
}

// Future<void> fetchPosters() async {
//   try {
//     QuerySnapshot querySnapshot =
//     await FirebaseFirestore.instance.collection('poster').get();
//
//     _posters = await Future.wait(querySnapshot.docs.map((doc) async {
//       Reference ref = FirebaseStorage.instance.ref().child(doc['imgUrl']);
//       String imgUrl = await ref.getDownloadURL();
//
//       return PosterModel(
//         id: doc['id'],
//         title: doc['title'],
//         description: doc['description'],
//         location: doc['location'],
//         startDate: doc['startDate'],
//         endDate: doc['endDate'],
//         posterUrl: doc['posterUrl'],
//
//
//       );
//     }).toList());
//
//     notifyListeners();
//   } catch (e) {
//     print('포스터를 가져오는 중 오류 발생: $e');
//   }
// }
//
// Future<String> getFirebaseStorageUrl(String imagePath) async {
//   try {
//     Reference ref = FirebaseStorage.instance.ref('posters').child(imagePath);
//     String downloadURL = await ref.getDownloadURL();
//     return downloadURL;
//   } catch (e) {
//     print('Firebase Storage URL을 가져오는 중 오류 발생: $e');
//     return '';
//   }
// }