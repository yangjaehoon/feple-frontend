import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_write_board.dart';

class CommunityPost extends StatefulWidget {
  final String boardname;
  final List<String> boardTitle;
  final List<String> boardDay;
  final List<String> boardFavorite;
  final List<String> boardComment;

  const CommunityPost(
      {super.key,
      required this.boardname,
      required this.boardTitle,
      required this.boardDay,
      required this.boardFavorite,
      required this.boardComment});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  DatabaseReference? ref;

  void initstate() {
    String boardref = 'board/${widget.boardname}';
    ref = FirebaseDatabase.instance.ref(boardref);
    setpost();
  }
  //firebase의 경우 기본적으로 앱 다시 시작 또는 페이지 새로고침 후 사용자의 인증 상태가 유지되도록 지원

  // final List<String> entries = <String>[];
  Future setpost() async {
    ref?.set({});
  }

  // Future getpost() async {
  //   final snapshot = await ref?.child('Post').get();
  //   return snapshot?.value;
  // }

  // ignore: prefer_typing_uninitialized_variables
  // var chooseboard;

  @override
  Widget build(BuildContext context) {
    initstate();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: 600,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.boardTitle.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    widget.boardTitle[index],
                  ),
                  subtitle: Text(widget.boardDay[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded),
                      Text(
                        widget.boardFavorite[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Icon(Icons.comment),
                      Text(
                        widget.boardComment[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(thickness: 2);
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
        ],
      ),
    );
  }
}
// return Container(
//   height: 50,
//   color: const Color.fromARGB(255, 0, 0, 0),
//   child: FutureBuilder(
//     future: getpost(),
//     builder: (BuildContext context, AsyncSnapshot snapshot) {
//       return Text(snapshot.data.toString());
//     },
//   ), //entries[index]
// );  //Entry ${entries[index]}