import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';

class HotBoard extends StatefulWidget {
  const HotBoard({super.key});

  @override
  State<StatefulWidget> createState() => _HotBoardState();
}

class _HotBoardState extends State<HotBoard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(
            width: 500,
            height: 200,
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
                Material(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: ((context) =>
                                const CommunityPost(boardname: "HotBoard")),
                          ));
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 36, 36, 36),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.all(10),
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
                                style: TextStyle(
                                    fontSize: 13, color: Colors.white),
                              ),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(
                  thickness: 2,
                  height: 1,
                  color: Colors.black,
                ),
                // ListView.builder(
                //   itemBuilder:
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
