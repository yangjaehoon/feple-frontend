import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChangeNickname extends StatelessWidget {
  const ChangeNickname({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController _controller = TextEditingController();

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
              ElevatedButton(onPressed: (){

              }, child: Text("확인")),
        ]));
  }
}
