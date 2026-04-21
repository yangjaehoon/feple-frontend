import 'package:flutter/material.dart';
import '../../model/festival_model.dart';
import '../../network/dio_client.dart';

class FestivalProvider extends ChangeNotifier {
  List<FestivalModel> _posters = [];
  List<FestivalModel> get posters => _posters;

  FestivalProvider() {
    fetchPosters();
  }

  Future<void> fetchPosters() async {
    try {
      final response = await DioClient.dio.get('/festivals');

      if (response.statusCode == 200) {
        final List data = response.data;

        _posters = data.map((json) => FestivalModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (_) {
    }
  }
}
