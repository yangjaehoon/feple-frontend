import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';

class HotBoard extends StatefulWidget {
  const HotBoard({super.key});

  @override
  State<StatefulWidget> createState() => _HotBoardState();
}

class _HotBoardState extends State<HotBoard> {
  List<String> hotboardTitle = [
    '한요한 대박이에요!!',
    '애쉬아일랜드 너무 멋있다..',
    '릴러말즈 사랑해',
  ];

  List<String> hotboardDay = [
    '10/15',
    '10/14',
    '10/13',
  ];

  List<String> hotboardFavorite = [
    '13',
    '60',
    '777',
  ];

  List<String> hotboardComment = [
    '4',
    '9',
    '14',
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
                    builder: ((context) => CommunityPost(
                          boardname: "HotBoard",
                          boardTitle: hotboardTitle,
                          boardDay: hotboardDay,
                          boardFavorite: hotboardFavorite,
                          boardComment: hotboardComment,
                        )),
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
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemExtent: 50,
              itemCount: hotboardTitle.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    hotboardTitle[index],
                  ),
                  subtitle: Text(hotboardDay[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded),
                      Text(
                        hotboardFavorite[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Icon(Icons.comment),
                      Text(
                        hotboardComment[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
