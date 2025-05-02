import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../config.dart';
import '../model/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;


  //파이버에비스에서 닉네임 가져오기
  // Future<void> fetchUserData() async {
  //   try {
  //     // Firebase에서 현재 사용자의 UID 가져오기
  //     String uid = auth.FirebaseAuth.instance.currentUser!.uid;
  //
  //
  //     // HTTP GET 요청 보내기
  //     final response = await http.get(Uri.parse('http://13.209.108.218:8080/users/user?uid=$uid'));
  //
  //     if (response.statusCode == 200) {
  //       final jsonResponse = jsonDecode(response.body);
  //       _user = User.fromJson(jsonResponse);
  //       notifyListeners();
  //     } else {
  //       throw Exception('Failed to load user data');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to fetch user data: $e');
  //   }
  // }

  Future<void> fetchUser(int userId) async {
    print("🔍 fetchUser 호출: userId=$userId");
    final resp = await http.get(Uri.parse('$baseUrl/users/$userId'));
    print("🛰  fetchUser 응답 상태: ${resp.statusCode}");
    print("\n 📦  fetchUser 응답 바디: ${resp.body}");
    if (resp.statusCode == 200) {
      _user = User.fromJson(jsonDecode(resp.body));
      print("✅ User 파싱 완료: id=${_user!.id}, nickname=${_user!.nickname}");
      notifyListeners();
    } else {
      print("❌ 사용자 정보 불러오기 실패");
      throw Exception('사용자 정보 불러오기 실패: ${resp.statusCode}');
    }


  }

  void setUser(User me) {
    print("🔧 setUser 호출: id=${me.id}, nickname=${me.nickname}");
    _user = me;
    notifyListeners();
  }
}
