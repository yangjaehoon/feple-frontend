import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart';
import '../network/dio_client.dart';
import 'package:dio/dio.dart';

class UserProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _kUserJson = 'userJson';

  User? _user;
  User? get user => _user;

  UserProvider() {
    _loadFromSecureStorage();
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

  Future<void> _loadFromSecureStorage() async {
    final token = await TokenStore.readAccessToken();
    if (token == null) {
      await _storage.delete(key: _kUserJson);
      return;
    }

    final jsonString = await _storage.read(key: _kUserJson);
    if (jsonString != null) {
      final data = jsonDecode(jsonString);
      _user = User.fromJson(data);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await TokenStore.clear();
    await _storage.delete(key: _kUserJson);
    _user = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final id = _user?.id;
    if (id == null) return;
    await DioClient.dio.delete('/users/$id');
    await logout();
  }

  Future<void> setUser(User me) async {
    _user = me;
    notifyListeners();
    await _storage.write(
      key: _kUserJson,
      value: jsonEncode({
        'id': me.id,
        'nickname': me.nickname,
        'profileImageUrl': me.profileImageUrl,
      }),
    );
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
