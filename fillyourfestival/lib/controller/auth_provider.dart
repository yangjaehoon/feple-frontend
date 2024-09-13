// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:fast_app_base/login/login.dart';
// import 'package:fast_app_base/app.dart';
// import 'package:flutter/material.dart';
//
// class AuthController extends GetxController {
//   static AuthController instance = Get.find();
//   late Rx<User?> _user;
//   FirebaseAuth authentication = FirebaseAuth.instance;
//
//   String _response = '';
//
//   Future<void> sendData() async {
//     Map<String, dynamic> postData = {
//       "nickname": "unknown",
//       "uid": FirebaseAuth.instance.currentUser?.uid,
//       "follow_artist": []
//     };
//
//     final response = await http.post(
//       Uri.parse('http://13.209.108.218:8080/users/save'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       },
//       body: jsonEncode(postData),
//     );
//     if (response.statusCode == 200) {
//       _response = response.body;
//     } else {
//       throw Exception('Failed to send data');
//     }
//   }
//
//   @override
//   void onReady() {
//     super.onReady();
//     _user = Rx<User?>(authentication.currentUser);
//     _user.bindStream(authentication.userChanges());
//     ever(_user, _moveToPage);
//   }
//
//   _moveToPage(User? user) {
//     if (user == null) {
//       Get.offAll(() => const LoginPage());
//     } else {
//       Get.offAll(() => const App());
//     }
//   }
//
//   void loginregister(String email, password) async {
//     try {
//       await authentication.signInWithEmailAndPassword(
//           email: email, password: password);
//     } catch (e) {
//       Get.snackbar(
//         "Error message",
//         "User message",
//         backgroundColor: Colors.red,
//         snackPosition: SnackPosition.BOTTOM,
//         titleText: const Text(
//           "Registration is failed",
//           style: TextStyle(color: Colors.white),
//         ),
//         messageText: Text(
//           e.toString(),
//           style: const TextStyle(color: Colors.white),
//         ),
//       );
//     }
//   }
//
//   void register(String email, password) async {
//     try {
//       await authentication.createUserWithEmailAndPassword(
//           email: email, password: password);
//       sendData();
//     } catch (e) {
//       Get.snackbar(
//         "Error message",
//         "User message",
//         backgroundColor: Colors.red,
//         snackPosition: SnackPosition.BOTTOM,
//         titleText: const Text(
//           "Registration is failed",
//           style: TextStyle(color: Colors.white),
//         ),
//         messageText: Text(
//           e.toString(),
//           style: const TextStyle(color: Colors.white),
//         ),
//       );
//     }
//   }
//
//   void logout() {
//     authentication.signOut();
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _response = '';

  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    notifyListeners();
  }

  Future<void> sendData() async {
    Map<String, dynamic> postData = {
      "nickname": "unknown",
      "uid": _auth.currentUser?.uid,
      "follow_artist": []
    };

    //print(postData['uid']); //uid값 확인
    Fluttertoast.showToast(msg: postData['uid']);

    final response = await http.post(
      Uri.parse('http://13.209.108.218:8080/users/save'),
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

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw e;
    }
  }

  Future<void> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await sendData();
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
