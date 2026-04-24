import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/network/dio_client.dart';

class UserService {
  Future<User> fetchUser(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId');
    if (resp.statusCode != 200) {
      throw Exception('사용자 정보 불러오기 실패: ${resp.statusCode}');
    }
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;
    if (raw is! Map<String, dynamic>) throw Exception('사용자 정보 형식 오류');
    return User.fromJson(raw);
  }

  Future<User> fetchUserFromToken(String token) async {
    final res = await DioClient.dio.get(
      '/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return User.fromJson(res.data);
  }

  Future<void> deleteUser(int userId) async {
    await DioClient.dio.delete('/users/$userId');
  }
}
