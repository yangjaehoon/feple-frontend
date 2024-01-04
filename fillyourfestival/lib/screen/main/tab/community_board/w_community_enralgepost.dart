import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/d_post.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:core';

class EnralgePost extends StatefulWidget {
  final String boardname;
  final String posttitle;
  final Post postdata;
  const EnralgePost(
      {super.key,
      required this.boardname,
      required this.posttitle,
      required this.postdata});

  @override
  State<EnralgePost> createState() => _EnralgePostState();
}

class _EnralgePostState extends State<EnralgePost> {
  var commentController = TextEditingController();

  DatabaseReference? ref;

  Future updatepost() async {
    String boardref = 'board/${widget.boardname}/Post/${widget.posttitle}';
    ref = FirebaseDatabase.instance.ref(boardref);
    widget.postdata.comments.add(commentController.text.trim());
    ref?.update({
      "userId": widget.postdata.userId,
      "content": widget.postdata.content,
      "time": widget.postdata.time,
      "heart": widget.postdata.heart,
      "favorite": widget.postdata.favorite,
      "comments": widget.postdata.comments
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
      ),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: 500,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        widget.posttitle,
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                    height: 1,
                    color: Color.fromARGB(255, 110, 110, 110),
                  ),
                  SizedBox(
                    width: 500,
                    height: 200,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(widget.postdata.content),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded),
                        Text(
                          widget.postdata.heart.toString(),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const Icon(Icons.comment),
                        Text(
                          widget.postdata.comments.length.toString(),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      FloatingActionButton.extended(
                        backgroundColor: Colors.black,
                        onPressed: () {
                          widget.postdata.heart = widget.postdata.heart + 1;
                          updatepost();
                        },
                        label: const Text('좋아요'),
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                        ),
                      ),
                      FloatingActionButton.extended(
                        backgroundColor: Colors.black,
                        onPressed: () {
                          widget.postdata.favorite =
                              widget.postdata.favorite + 1;
                          updatepost();
                        },
                        label: const Text('즐겨찾기'),
                        icon: const Icon(
                          Icons.grade,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: widget.postdata.comments.length,
                    itemBuilder: (context, int index) {
                      return ListTile(
                        title: Text(
                          widget.postdata.userId,
                        ),
                        subtitle: Text(widget.postdata.comments[index]),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider(thickness: 2);
                    },
                  ),
                  //TODO BottomNavigationBar 없애기 작업
                  Positioned(
                    top: 300,
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        border: InputBorder.none, hintText: '댓글을 입력하세요.'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
