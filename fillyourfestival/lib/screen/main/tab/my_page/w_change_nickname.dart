import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../../controller/auth_provider.dart';
import '../../../../model/user_model.dart';
import '../../../../provider/user_provider.dart';

class ChangeNickname extends StatefulWidget {
  const ChangeNickname({super.key});

  @override
  State<ChangeNickname> createState() => _ChangeNicknameState();
}

class _ChangeNicknameState extends State<ChangeNickname> {
  var nicknameController = TextEditingController();

  String _response = '';

  Future<void> updatepost() async {
    String nicknameuri = 'http://13.209.108.218:8080/users/nickname';

    String nickname = nicknameController.text.trim();
    Map<String, dynamic> postData = {"nickname": nickname};

    final response = await http.post(
      Uri.parse(nicknameuri),
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
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    User? user = userProvider.user;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          Text(
            "변경할 닉네임을 입력해주세요.",
            style: TextStyle(fontSize: 22),
          ),
          TextField(
            controller: nicknameController,
            style: TextStyle(fontSize: 22, color: Colors.blue),
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'ex) 페벌러'),
          ),
          ElevatedButton(
              onPressed: () async {
                updatepost();
                Navigator.pop(context);
              },
              child: Text("확인")),
        ]));
  }

// void updateNickname() async{
//   Map<String, dynamic> requestData = {
//     "nickname": ,
//   }
// }
}
