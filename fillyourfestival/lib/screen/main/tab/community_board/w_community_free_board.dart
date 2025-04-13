import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../config.dart';
import '../../../../model/post_model.dart';
import '../../../../service/post_service.dart';

class FreeBoard extends StatefulWidget {
  final String boardname;

  const FreeBoard({super.key, required this.boardname});

  @override
  State<FreeBoard> createState() => _FreeBoardState();
}

class _FreeBoardState extends State<FreeBoard> {
  final PostService postService = PostService();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 54, 54, 54),
        border: Border.all(
          color: Colors.black,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            width: 500,
            height: 40,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 34, 34, 34),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: ((context) =>
                          const CommunityPost(boardname: "FreeBoard")),
                    ));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "자유 게시판",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "더보기",
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            thickness: 2,
            height: 1,
            color: Colors.black,
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
                future: postService.fetchPosts('FreeBoard'),
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
                    List postDataList = snapshot.data!;
                    if (postDataList.isEmpty) {
                      return const Center(
                        child: Text('No data available.'),
                      );
                    } else {
                      return ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: postDataList.length,
                          itemBuilder: (context, int index) {
                            Post postData = postDataList[index];
                            return ListTile(
                              title: Text(
                                postData.title,
                              ),
                              subtitle: Text(postData.nickname),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite_rounded),
                                  Text(
                                    postData.likeCount.toString(),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const Icon(Icons.comment),
                                  // Text(
                                  //   postData['comments'].length.toString(),
                                  //   style: const TextStyle(fontSize: 20),
                                  // ),
                                ], //TODO comments나중에 수정 필요함
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return const Divider(thickness: 2);
                          });
                    }
                  }
                }),
          ),
        ],
      ),
    );
  }
}
