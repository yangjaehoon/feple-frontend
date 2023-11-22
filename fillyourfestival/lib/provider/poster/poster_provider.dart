import 'package:fast_app_base/provider/poster/get_img_url.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../model/poster_model.dart';


class PosterProvider extends ChangeNotifier {
  List<PosterModel> _posters = [];

  List<PosterModel> get posters => _posters;


  PosterProvider() {
    fetchPosters();
  }

  Future<void> fetchPosters() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('poster').get();

      _posters = await Future.wait(querySnapshot.docs.map((doc) async {
        Reference _ref = FirebaseStorage.instance.ref().child(doc['imgUrl']);
        String _imgUrl = await _ref.getDownloadURL();

        return PosterModel(
          date: doc['date'],
          id: doc['id'],
          imgUrl: _imgUrl,
          location: doc['location'],
          name: doc['name'],
        );
      }).toList());

      notifyListeners();
    } catch (e) {
      print('포스터를 가져오는 중 오류 발생: $e');
    }
  }

  Future<String> getFirebaseStorageUrl(String imagePath) async {
    try {
      // 'posters'가 Firebase Storage 버킷의 이름이라고 가정합니다.
      Reference ref = FirebaseStorage.instance.ref('posters').child(imagePath);
      String downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Firebase Storage URL을 가져오는 중 오류 발생: $e');
      return ''; // 적절하게 오류 처리
    }
  }
}