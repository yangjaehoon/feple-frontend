import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../config.dart';
import '../../model/poster_model.dart';
import '../../network/dio_client.dart';


class PosterProvider extends ChangeNotifier {
  List<PosterModel> _posters = [];
  List<PosterModel> get posters => _posters;

  PosterProvider() {
    fetchPosters();
  }

  Future<void> fetchPosters() async {
    try {
      final response = await DioClient.dio.get('/festivals');

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
