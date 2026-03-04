import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart';
import '../network/dio_client.dart';
import 'package:dio/dio.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  UserProvider() {
    _loadFromPrefs();
  }

  Future<void> fetchUser(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId');

    if (resp.statusCode == 200) {
      final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
      _user = User.fromJson(data as Map<String, dynamic>);
      notifyListeners();
    } else {
      throw Exception('사용자 정보 불러오기 실패: ${resp.statusCode}');
    }
  }

  Future<void> _loadFromPrefs() async {
    // JWT 토큰이 없으면 로그인 페이지로 돌아가야 하므로 user를 복원하지 않음
    final token = await TokenStore.readAccessToken();
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userJson');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('userJson');
    if (jsonString != null) {
      final data = jsonDecode(jsonString);
      _user = User.fromJson(data);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await TokenStore.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userJson');
    _user = null;
    notifyListeners();
  }

  Future<void> setUser(User me) async{
    _user = me;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userJson', jsonEncode({
      'id': me.id,
      'nickname': me.nickname,
      'profileImageUrl': me.profileImageUrl,
    }));
  }

  Future<void> fetchUserFromToken(String token) async {
    try {
      final dio = DioClient.dio;
      final res = await dio.get(
        '/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      _user = User.fromJson(res.data);
      notifyListeners();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        _user = null;
        await TokenStore.clear();
        notifyListeners();
      }
      // 그 외 오류(404, 네트워크 등)는 기존 user 유지
      rethrow;
    }
  }
}
