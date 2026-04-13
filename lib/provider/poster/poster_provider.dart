import 'package:flutter/material.dart';
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
      }
    } catch (_) {
    }
  }
}
