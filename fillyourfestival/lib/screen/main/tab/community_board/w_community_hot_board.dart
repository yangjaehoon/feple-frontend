import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HotBoard extends StatefulWidget {
  final String boardname;

  const HotBoard({super.key, required this.boardname});

  @override
  State<StatefulWidget> createState() => _HotBoardState();
}

class _HotBoardState extends State<HotBoard> {
  Future<List<dynamic>> getpost() async {
    final response =
        await http.get(Uri.parse('http://13.209.108.218:8080/hotboards/previews'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load hot boards');
    }
  }

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
                        const CommunityPost(boardname: "HotBoard")),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "인기 게시판",
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
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: postDataList.length,
                          itemBuilder: (context, int index) {
                            Map<String, dynamic> postData = postDataList[index];
                            return ListTile(
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
                                ], //TODO comments 나중에 수정해야함
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
