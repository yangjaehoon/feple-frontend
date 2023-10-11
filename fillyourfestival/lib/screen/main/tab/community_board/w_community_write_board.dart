import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PencilWidget extends StatelessWidget {
  final String boardname;
  const PencilWidget({super.key, required this.boardname});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.grey[800],
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WritePost(boardname: boardname,)),
        );
      },
      label: const Text('글 쓰기'),
      icon: const Icon(
        Icons.edit,
        color: Colors.red,
      ),
    );
  }
}

class WritePost extends StatefulWidget {
  final String boardname;
  const WritePost({super.key, required this.boardname});

  @override
  State<WritePost> createState() => _WritePostState();
}

class _WritePostState extends State<WritePost> {
  
  void initstate(){
    if (widget.boardname == "HotBoard") {
      DatabaseReference ref = FirebaseDatabase.instance.ref('board/HotBoard');

    }
    else if (widget.boardname == "GetuserBoard"){
      DatabaseReference ref = FirebaseDatabase.instance.ref('board/GetuserBoard');
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
              onPressed: () {},
              child: const Text("완료")),
        ],
      ),
      body: const Column(
        children: [
          TextField(
            decoration:
                InputDecoration(border: InputBorder.none, hintText: '제목'),
          ),
          Divider(
            thickness: 2,
            height: 1,
            color: Colors.white,
          ),
          TextField(
            //textAlign: TextAlign.justify,
            maxLines: null,
            decoration: InputDecoration(
                border: InputBorder.none, hintText: '내용을 입력하세요.'),
          ),
        ],
      ),
    );
  }
}
