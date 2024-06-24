import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart'  as http;
import '../model/user_model.dart';

class UserProvider with ChangeNotifier{

  User? _user;

  User? get user => _user;

  //http://13.209.108.218:8080/freeboards/previews
  Future<void> fetchUserData(String userId) async {
    final response = await http.get(Uri.parse('http://example.com/users/getuser?id=$userId'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      _user = User.fromJson(jsonResponse);
      notifyListeners();
    } else {
      throw Exception('Failed to load user data');
    }
  }
}