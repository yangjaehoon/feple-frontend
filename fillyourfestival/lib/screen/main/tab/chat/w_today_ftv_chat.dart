import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/chat/w_chatting_room.dart';
import 'package:provider/provider.dart';
import '../../../../provider/poster/poster_provider.dart';

class TodayFtvChat extends StatefulWidget {
  const TodayFtvChat({super.key});

  @override
  State<TodayFtvChat> createState() => _TodayFtvChatState();
}

class _TodayFtvChatState extends State<TodayFtvChat> {
  @override
  Widget build(BuildContext context) {
    final poster = Provider.of<PosterProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 8.0),
            child: Text(
              "Today's Festival",
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(
            height: 200,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Material(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: ((context) => ChattingRoom(
                                          chattingroomname: poster.posters[index].name)),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image(
                                    image: NetworkImage(poster.posters[index].imgUrl),
                                    fit: BoxFit.cover,
                                    width: 150,
                                    height: 200,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                width: 150,
                                height: 30,
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              poster.posters[index].name,
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: poster.posters.length, // 아이템의 개수
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
