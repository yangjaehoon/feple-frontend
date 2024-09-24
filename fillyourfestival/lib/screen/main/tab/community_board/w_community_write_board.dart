import 'package:flutter/material.dart';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WritePost extends StatefulWidget {
  final String boardname;

  const WritePost({super.key, required this.boardname});

  @override
  State<WritePost> createState() => _WritePostState();
}

class _WritePostState extends State<WritePost> {
  var nameController = TextEditingController();
  var contentController = TextEditingController();

  String _response = ''; //응답 값 저장

  Future<void> updatepost() async {
    String boarduri = '';
    if (widget.boardname == "FreeBoard") {
      boarduri = 'http://13.209.108.218:8080/freeboards/save';
    } else if (widget.boardname == "HotBoard") {
      boarduri = 'http://13.209.108.218:8080/hotboards/save';
    } else if (widget.boardname == "GetuserBoard") {
      boarduri = 'http://13.209.108.218:8080/getuserboards/save';
    }

    String title = nameController.text.trim();
    String content = contentController.text.trim();
    DateTime now = DateTime.now();
    String formattedDateTime = now.toIso8601String();
    Map<String, dynamic> postData = {
      "nickname": "unknown", //TODO 나중에 닉네임 입력 받으면 그걸로 업데이트 해야함
      "postname": title,
      "content": content,
      //"comments" : [],
      "datetime": formattedDateTime
    };

    final response = await http.post(
      Uri.parse(boarduri),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 쓰기'),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              updatepost();
              Navigator.pop(context);
            },
            child: const Text("완료"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: '제목'),
            ),
            const Divider(
              thickness: 2,
              height: 1,
              color: Colors.white,
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: '내용을 입력하세요.'),
            ),
          ],
        ),
      ),
    );
  }
}
