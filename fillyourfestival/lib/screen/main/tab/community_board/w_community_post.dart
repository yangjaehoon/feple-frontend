import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_write_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunityPost extends StatefulWidget {
  final String boardname;

  const CommunityPost({super.key, required this.boardname});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  Future<List<dynamic>> getpost() async {
    String boarduri = '';
    if (widget.boardname == "FreeBoard") {
      boarduri = 'http://10.0.2.2:8080/freeboards/all';
    } else if (widget.boardname == "HotBoard") {
      boarduri = 'http://10.0.2.2:8080/hotboards/all';
    } else if (widget.boardname == "GetuserBoard") {
      boarduri = 'http://10.0.2.2:8080/getuserboards/all';
    }
    final response = await http.get(Uri.parse(boarduri));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load free boards');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
      ),
      body: Stack(children: [
        SizedBox(
          height: 600,
          child: FutureBuilder(
              future: getpost(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load data: ${snapshot.error}'),
                  );
                } else {
                  List<dynamic> postDataList = snapshot.data!;
                  if (postDataList.isEmpty) {
                    return const Center(
                      child: Text('No data available.'),
                    );
                  } else {
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: postDataList.length,
                      itemBuilder: (context, int index) {
                        Map<String, dynamic> postData = postDataList[index];
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: ((context) => EnralgePost(
                                      boardname: widget.boardname,
                                      id : postData['id'],
                                      nickname: postData['nickname'],
                                      postname: postData['postname'],
                                      content: postData['content'],
                                      comments: List<String>.from(postData['comments']),
                                      heart: postData['heart'],
                                      datetime: postData['datetime'],
                                      favorite: postData['favorite'],
                                    )),
                              ),
                            );
                          },
                          title: Text(
                            postData['postname'],
                          ),
                          subtitle: Text(postData['datetime']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_rounded),
                              Text(
                                postData['favorite'].toString(),
                                style: const TextStyle(fontSize: 20),
                              ),
                              const Icon(Icons.comment),
                              Text(
                                postData['comments'].length.toString(),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider(thickness: 2);
                      },
                    );
                  }
                }
              }),
        ),
        Positioned(
          bottom: 40,
          left: 150,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.grey[800],
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WritePost(
                    boardname: widget.boardname,
                  ),
                ),
              );
            },
            label: const Text('글 쓰기'),
            icon: const Icon(
              Icons.edit,
              color: Colors.red,
            ),
          ),
        ),
      ]),
    );
  }
}
