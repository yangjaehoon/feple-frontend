import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityPost extends StatefulWidget {
  const CommunityPost({super.key});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  DatabaseReference ref = FirebaseDatabase.instance.ref("post");
<<<<<<< HEAD
  Future<String> helloWorld() {
    return Future.delayed(Duration(seconds: 15), () {
      return 'Hello World';
    });
  }
=======

>>>>>>> fdd5596ff3ea4a0d3d56a5c88c6bccb648cd26b8
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(8), children: [
      Container(
          height: 50,
          color: Colors.amber[600],
<<<<<<< HEAD
          child: const Center(
              //child: FutureBuilder(builder : (BuildContext context, AsyncSnap)),
          )
      ),
=======
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
>>>>>>> fdd5596ff3ea4a0d3d56a5c88c6bccb648cd26b8
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
<<<<<<< HEAD
=======

  Future _future() async {
    await Future.delayed(const Duration(seconds: 5));
    return ref.get();
  }
>>>>>>> fdd5596ff3ea4a0d3d56a5c88c6bccb648cd26b8
} //게시글 가져오기