import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:fast_app_base/login/login.dart';
import 'package:fast_app_base/app.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  late Rx<User?> _user;
  FirebaseAuth authentication = FirebaseAuth.instance;

  String _response = '';

  Future<void> sendData() async {
    Map<String, dynamic> postData = {
      "nickname": "unknown",
      "uid": FirebaseAuth.instance.currentUser?.uid,
      "follow_artist": []
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/users/save'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(postData),
    );
    if (response.statusCode == 200) {
      _response = response.body;
    } else {
      throw Exception('Failed to send data');
    }
  }

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(authentication.currentUser);
    _user.bindStream(authentication.userChanges());
    ever(_user, _moveToPage);
  }

  _moveToPage(User? user) {
    if (user == null) {
      Get.offAll(() => const LoginPage());
    } else {
      Get.offAll(() => const App());
    }
  }

  void loginregister(String email, password) async {
    try {
      await authentication.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      Get.snackbar(
        "Error message",
        "User message",
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        titleText: const Text(
          "Registration is failed",
          style: TextStyle(color: Colors.white),
        ),
        messageText: Text(
          e.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  void register(String email, password) async {
    try {
      await authentication.createUserWithEmailAndPassword(
          email: email, password: password);
      sendData();
    } catch (e) {
      Get.snackbar(
        "Error message",
        "User message",
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        titleText: const Text(
          "Registration is failed",
          style: TextStyle(color: Colors.white),
        ),
        messageText: Text(
          e.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  void logout() {
    authentication.signOut();
  }
}
