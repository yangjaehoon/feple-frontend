import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityPost extends StatefulWidget {
  const CommunityPost({super.key});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  DatabaseReference ref = FirebaseDatabase.instance.ref("post");

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(8), children: [
      Container(
          height: 50,
          color: Colors.amber[600],
          child: Center(
            child: FutureBuilder(
                future: _future(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData == false) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        snapshot.data.toString(),
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  }
                }),
          )),
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

  Future _future() async {
    await Future.delayed(const Duration(seconds: 5));
    return ref.get();
  }
} //게시글 가져오기