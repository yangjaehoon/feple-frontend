import 'package:fast_app_base/screen/main/tab/chat/w_fan_chat.dart';
import 'package:fast_app_base/screen/main/tab/chat/w_my_chat.dart';
import 'package:fast_app_base/screen/main/tab/chat/w_today_ftv_chat.dart';
import 'package:flutter/material.dart';

import '../home/w_fyf_app_bar.dart';


class ChatFragment extends StatelessWidget {
  const ChatFragment({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 60,
              bottom: 50,
            ), // 상단바 부분만큼 띄워줌(stack이여서),
            child: Column(
              children: [
                //TodayFtvChat(),
                //MyChat(),
                //FanChat(),
              ],
            ),
          ),
          //CircleArtistWidget(),
          FyfAppBar("채팅방"),
        ],
      ),
    );
  }
}
