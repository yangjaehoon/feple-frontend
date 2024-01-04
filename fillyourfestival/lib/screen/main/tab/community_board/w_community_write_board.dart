import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:core';

class WritePost extends StatefulWidget {
  final String boardname;
  const WritePost({super.key, required this.boardname});

  @override
  State<WritePost> createState() => _WritePostState();
}

class _WritePostState extends State<WritePost> {
  var nameController = TextEditingController();
  var contentController = TextEditingController();

  DatabaseReference? ref;

  Future updatepost() async {
    String boardref = 'board/${widget.boardname}/Post';
    ref = FirebaseDatabase.instance.ref(boardref);
    String title = nameController.text.trim();
    String content = contentController.text.trim();
    DateTime now = DateTime.now();
    ref?.update({
      title: {
        "userId": FirebaseAuth.instance.currentUser?.uid,
        "content": content,
        "time": now.toString(),
        "heart": 0,
        "favorite": 0,
        "comments": ["Hello", "suchang"],
      }
    });
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
