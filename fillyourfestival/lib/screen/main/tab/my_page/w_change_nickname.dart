import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controller/auth_provider.dart';
import '../../../../model/user_model.dart';
import '../../../../provider/user_provider.dart';

class ChangeNickname extends StatelessWidget {
  const ChangeNickname({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController _controller = TextEditingController();

    UserProvider userProvider = Provider.of<UserProvider>(context);
    User? user = userProvider.user;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          Text("변경할 닉네임을 입력해주세요.",style: TextStyle(fontSize: 22),),
          TextField(
            controller: _controller,
            style: TextStyle(fontSize: 22, color: Colors.blue),
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'ex) 페벌러'),
          ),
              ElevatedButton(onPressed: () async {

              }, child: Text("확인")),
        ]));
  }

  // void updateNickname() async{
  //   Map<String, dynamic> requestData = {
  //     "nickname": ,
  //   }
  // }
}
