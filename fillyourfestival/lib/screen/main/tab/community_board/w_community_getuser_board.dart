import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';

class Post {
  final List<String> comments;
  final String content, userId, time;
  final int heart, favorite;

  Post(
      {required this.comments,
      required this.content,
      required this.userId,
      required this.time,
      required this.heart,
      required this.favorite});

  factory Post.fromJson(json) {
    json.forEach((key, value) {});
    return Post(
      comments: List<String>.from(json['comments']),
      content: json['content'] as String,
      favorite: json['favorite'] as int,
      heart: json['heart'] as int,
      time: json['time'] as String,
      userId: json['userId'] as String,
    );
  }
}

class GetUserBoard extends StatefulWidget {
  final String boardname;

  const GetUserBoard({super.key, required this.boardname});

  @override
  State<GetUserBoard> createState() => _GetUserBoardState();
}

class _GetUserBoardState extends State<GetUserBoard> {
  DatabaseReference? ref;
  late Future postFuture;

  @override
  void initState() {
    super.initState();
    String boardref = 'board/${widget.boardname}';
    ref = FirebaseDatabase.instance.ref(boardref);
    postFuture = getpost();
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
                          const CommunityPost(boardname: "GetuserBoard")),
                    ));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "동행구하기 게시판",
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
            child: FutureBuilder(
              future: postFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasData) {
                  final posttitle = snapshot.data as Map;
                  return ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, int index) {
                        final postdata =
                            Post.fromJson(posttitle.valuesList()[index]);
                        return ListTile(
                          title: Text(
                            posttitle.keysList()[index],
                          ),
                          subtitle: Text(postdata.time),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_rounded),
                              Text(
                                postdata.favorite.toString(),
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
                      });
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
        ],
      ),
    );
  }
}
