import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_write_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'package:fast_app_base/screen/main/tab/community_board/d_post.dart';

class CommunityPost extends StatefulWidget {
  final String boardname;

  const CommunityPost({super.key, required this.boardname});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  DatabaseReference? ref;

  @override
  void initState() {
    super.initState();
    String boardref = 'board/${widget.boardname}';
    ref = FirebaseDatabase.instance.ref(boardref);
  }

  Future getpost() async {
    final snapshot = await ref?.child('Post').get();
    if (snapshot!.exists) {
      return snapshot.value;
    } else {
      setpost();
    }
  }

  Future setpost() async {
    ref?.set({});
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
              if (snapshot.data == null) {
                return const Scaffold();
              }
              else if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasData) {
                final posttitle = snapshot.data as Map;
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: posttitle.length,
                  itemBuilder: (context, int index) {
                    final postdata =
                        Post.fromJson(posttitle.valuesList()[index]);
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: ((context) => EnralgePost(
                                boardname: widget.boardname,
                                posttitle: posttitle.keysList()[index],
                                postdata: postdata)),
                          ),
                        );
                      },
                      title: Text(
                        posttitle.keysList()[index],
                      ),
                      subtitle: Text(postdata.time),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded),
                          Text(
                            postdata.heart.toString(),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const Icon(Icons.comment),
                          Text(
                            postdata.comments.length.toString(),
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
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text('데이터를 가져오는 중 오류가 발생했습니다.'),
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
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
