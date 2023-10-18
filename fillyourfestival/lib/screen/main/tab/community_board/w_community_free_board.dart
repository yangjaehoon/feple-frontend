import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';

class FreeBoard extends StatefulWidget {
  const FreeBoard({super.key});

  @override
  State<FreeBoard> createState() => _FreeBoardState();
}

class _FreeBoardState extends State<FreeBoard> {
  List<String> freeboardTitle = [
    '요즘 어떤 페스티벌이 재밌나요',
    '아 뭐하지',
    '페스티벌 가고싶다',
  ];

  List<String> freeboardDay = [
    '10/16',
    '10/16',
    '10/16',
  ];

  List<String> freeboardFavorite = [
    '0',
    '0',
    '1',
  ];

  List<String> freeboardComment = [
    '0',
    '0',
    '2',
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
                          CommunityPost(boardname: "FreeBoard", boardTitle: freeboardTitle, boardDay: freeboardDay,
                          boardFavorite: freeboardFavorite, boardComment: freeboardComment)),
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
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemExtent: 50,
              itemCount: freeboardTitle.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    freeboardTitle[index],
                  ),
                  subtitle: Text(freeboardDay[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded),
                      Text(
                        freeboardFavorite[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Icon(Icons.comment),
                      Text(
                        freeboardComment[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  // onTap: () {
                  //   print(hotboardName[index]);
                  // });
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
