import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EnralgePost extends StatefulWidget {
  String boardname;
  int id;
  String nickname;
  String postname;
  String content;
  List<String> comments;
  int heart;
  String datetime;
  int favorite;
  //final List<String> comments;
  EnralgePost(
      {super.key,
      required this.boardname,
      required this.id,
      required this.nickname,
      required this.postname,
      required this.content,
      required this.comments,
      required this.heart,
      required this.datetime,
      required this.favorite});

  @override
  State<EnralgePost> createState() => _EnralgePostState();
}

class _EnralgePostState extends State<EnralgePost> {
  var commentController = TextEditingController();

  void updatepost() async {
    String boarduri = '';
    if (widget.boardname == "FreeBoard") {
      boarduri = 'http://13.209.108.218:8080/freeboards/update';
    } else if (widget.boardname == "HotBoard") {
      boarduri = 'http://13.209.108.218:8080/hotboards/update';
    } else if (widget.boardname == "GetuserBoard") {
      boarduri = 'http://13.209.108.218:8080/getuserboards/update';
    }
    Map<String, dynamic> requestData = {
      "id": widget.id,
      "nickname": widget.nickname,
      "postname": widget.postname,
      "content": widget.content,
      "comments": widget.comments.cast<String>(),
      "heart": widget.heart,
      "datetime": widget.datetime,
      "favorite": widget.favorite,
    };
    final response = await http.post(
      Uri.parse(boarduri),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestData),
    );
    if (response.statusCode == 200) {
      print("update");
    } else {
      print('Failed to load post');
    }
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
                        widget.postname,
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
                      child: Text(widget.content),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded),
                        Text(
                          widget.heart.toString(),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const Icon(Icons.comment),
                        // Text(
                        //   widget.postdata.comments.length.toString(),
                        //   style: const TextStyle(fontSize: 20),
                        // ), //TODO 댓글(comment)관련 작업해야함
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      FloatingActionButton.extended(
                        backgroundColor: Colors.black,
                        onPressed: () {
                          widget.heart = widget.heart + 1;
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
                          widget.favorite = widget.favorite + 1;
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
                  // ListView.separated(
                  //   physics: const NeverScrollableScrollPhysics(),
                  //   shrinkWrap: true,
                  //   itemCount: widget.comments.length,
                  //   itemBuilder: (context, int index) {
                  //     return ListTile(
                  //       title: Text(
                  //         widget.userId,
                  //       ),
                  //       subtitle: Text(widget.comments[index]),
                  //     );
                  //   },
                  //   separatorBuilder: (BuildContext context, int index) {
                  //     return const Divider(thickness: 2);
                  //   },
                  // ), //TODO 댓글(comment)관련 작업해야함
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
