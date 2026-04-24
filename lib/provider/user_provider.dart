import 'dart:convert';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart';
import 'package:dio/dio.dart';

class UserProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _kUserJson = 'userJson';

  final UserService _userService;

  User? _user;
  User? get user => _user;

  UserProvider(this._userService) {
    _loadFromSecureStorage();
  }

  Future<void> fetchUser(int userId) async {
    _user = await _userService.fetchUser(userId);
    notifyListeners();
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
    await _userService.deleteUser(id);
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
      _user = await _userService.fetchUserFromToken(token);
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
