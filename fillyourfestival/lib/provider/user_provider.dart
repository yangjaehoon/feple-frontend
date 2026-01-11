import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../model/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  UserProvider() {
    _loadFromPrefs();
  }

  Future<void> fetchUser(int userId) async {
    print(" fetchUser 호출: userId=$userId");
    final resp = await http.get(Uri.parse('$baseUrl/users/$userId'));
    print("  fetchUser 응답 상태: ${resp.statusCode}");
    print("\n 📦  fetchUser 응답 바디: ${resp.body}");
    if (resp.statusCode == 200) {
      _user = User.fromJson(jsonDecode(resp.body));
      //print("✅ User 파싱 완료: id=${_user!.id}, nickname=${_user!.nickname}");
      notifyListeners();
    } else {
      print(" 사용자 정보 불러오기 실패");
      throw Exception('사용자 정보 불러오기 실패: ${resp.statusCode}');
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('userJson');
    if (jsonString != null) {
      final data = jsonDecode(jsonString);
      _user = User.fromJson(data);
      notifyListeners();
    }
    else
      print("왜 없쥐~~");
  }

  Future<void> setUser(User me) async{
    print("setUser 호출: id=${me.id}, nickname=${me.nickname}");
    _user = me;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userJson', jsonEncode({
      'id': me.id,
      'nickname': me.nickname,
      'profileImageUrl': me.profileImageUrl,
    }));
  }
}
