import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';

class GetUserBoard extends StatefulWidget {
  const GetUserBoard({super.key});

  @override
  State<GetUserBoard> createState() => _GetUserBoardState();
}

class _GetUserBoardState extends State<GetUserBoard> {
  List<String> getuserboardTitle = [
    '랩비트 페스티벌 같이 가실분 있나요?',
    '같이 페스티벌 가실분~?',
    '페스티벌 갈 사람 구합니다.',
  ];

  List<String> getuserboardDay = [
    '10/16',
    '10/16',
    '10/16',
  ];

  List<String> getuserboardFavorite = [
    '0',
    '0',
    '0',
  ];

  List<String> getuserboardComment = [
    '6',
    '1',
    '1',
  ];

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
                          CommunityPost(boardname: "GetuserBoard", boardTitle: getuserboardTitle, boardDay: getuserboardDay,
                          boardFavorite: getuserboardFavorite, boardComment: getuserboardComment)),
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
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemExtent: 50,
              itemCount: getuserboardTitle.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    getuserboardTitle[index],
                  ),
                  subtitle: Text(getuserboardDay[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded),
                      Text(
                        getuserboardFavorite[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Icon(Icons.comment),
                      Text(
                        getuserboardComment[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  // onTap: () {
                  //   print(hotboardName[index]);
                  // }); //여기서부터는 firebase랑 연동해서 해야함.
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
