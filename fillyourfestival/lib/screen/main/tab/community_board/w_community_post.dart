import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityPost extends StatefulWidget {
  const CommunityPost({super.key});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  DatabaseReference ref = FirebaseDatabase.instance.ref("post");
  Future<String> helloWorld() {
    return Future.delayed(Duration(seconds: 15), () {
      return 'Hello World';
    });
  }
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(8), children: [
      Container(
          height: 50,
          color: Colors.amber[600],
          child: const Center(
              //child: FutureBuilder(builder : (BuildContext context, AsyncSnap)),
          )
      ),
      Container(
          height: 50,
          color: Colors.amber[500],
          child: const Center(child: Text('22222'))),
      Container(
          height: 50,
          color: Colors.amber[400],
          child: const Center(child: Text('33333'))),
    ]);
  }
} //게시글 가져오기