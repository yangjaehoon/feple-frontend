import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityPost extends StatefulWidget {
  const CommunityPost({super.key});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  DatabaseReference ref = FirebaseDatabase.instance.ref('board/post');

  //firebase의 경우 기본적으로 앱 다시 시작 또는 페이지 새로고침 후 사용자의 인증 상태가 유지되도록 지원

  final List<String> entries = <String>[];

  Future setpost() async {
    await ref.set({
      hashCode : "post name",
      "first": "first_post",
      "second": "second_post",
    });
  } //post들을 입력하는 영역

  Future getpost() async {
    final snapshot = await ref.child('second').get();
    return snapshot.value;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: (BuildContext context, int index) {
      return Container(
        height: 50,
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FutureBuilder(
            future: getpost(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return Text(snapshot.data.toString());
            }),
        //entries[index]
      );
    }); //Entry ${entries[index]}
  }
}
