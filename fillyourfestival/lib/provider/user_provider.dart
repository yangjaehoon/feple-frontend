import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../model/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  Future<void> fetchUserData() async {
    try {
      // Firebase에서 현재 사용자의 UID 가져오기
      String uid = auth.FirebaseAuth.instance.currentUser!.uid;


      // HTTP GET 요청 보내기
      final response = await http.get(Uri.parse('http://13.209.108.218:8080/users/user?uid=$uid'));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _user = User.fromJson(jsonResponse);
        notifyListeners();
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }
}
