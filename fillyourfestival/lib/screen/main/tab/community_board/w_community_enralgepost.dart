import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../config.dart';

class EnralgePost extends StatefulWidget {
  String boardname;
  int id;
  String nickname;
  String title;
  String content;

  //List<String> comments;
  int heart;

  //String datetime;
  //int favorite;
  //final List<String> comments;
  EnralgePost({
    super.key,
    required this.boardname,
    required this.id,
    required this.nickname,
    required this.title,
    required this.content,
    //required this.comments,
    required this.heart,
    //required this.datetime,
    //required this.favorite
  });

  @override
  State<EnralgePost> createState() => _EnralgePostState();
}

class _EnralgePostState extends State<EnralgePost> {
  var commentController = TextEditingController();

  static const _endpoints = {
    'FreeBoard': '/posts/free',
    'HotBoard': '/posts/hot',
    'GetuserBoard': '/posts/mate',
  };

  void updatepost() async {
    final urlPath = _endpoints[widget.boardname];
    if (urlPath == null) {
      throw Exception('알 수 없는 게시판: ${widget.boardname}');
    }
    final uri = Uri.parse('$baseUrl$urlPath');

    Map<String, dynamic> requestData = {
      "id": widget.id,
      "nickname": widget.nickname,
      "title": widget.title,
      "content": widget.content,
      //"comments": widget.comments.cast<String>(),
      //"heart": widget.heart,
      //"datetime": widget.datetime,
      //"favorite": widget.favorite,
    };
    final response = await http.post(
      uri,
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
            widget.title,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          const Divider(
            thickness: 2,
            height: 24,
            color: Color.fromARGB(255, 110, 110, 110),
          ),
          Text(widget.content,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16,),
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                widget.heart.toString(),
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.comment, color: Colors.white),
              // Text(
              //   widget.postdata.comments.length.toString(),
              //   style: const TextStyle(fontSize: 20),
              // ), //TODO 댓글(comment)관련 작업해야함
            ],
          ),
          const SizedBox(height: 16),
        Row(
          children: [
            FloatingActionButton.extended(
              backgroundColor: Colors.black,
              onPressed: () {
                setState(() {
                  widget.heart++;
                });
                updatepost();
              },
              label: const Text('좋아요'),
              icon: const Icon(
                Icons.favorite_rounded,
                color: Colors.red,
              ),
            ),
            // FloatingActionButton.extended(
            //   backgroundColor: Colors.black,
            //   onPressed: () {
            //     widget.favorite = widget.favorite + 1;
            //     updatepost();
            //   },
            //   label: const Text('즐겨찾기'),
            //   icon: const Icon(
            //     Icons.grade,
            //     color: Colors.yellow,
            //   ),
            // ),
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
    ),
    );
  }
}
