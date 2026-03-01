import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/screen/main/tab/chat/w_fan_chat.dart';
import 'package:fast_app_base/screen/main/tab/chat/w_my_chat.dart';
import 'package:fast_app_base/screen/main/tab/chat/w_today_ftv_chat.dart';
import 'package:flutter/material.dart';

import '../home/w_feple_app_bar.dart';


class ChatFragment extends StatelessWidget {
  const ChatFragment({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.backgroundMain,
      child: const Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: AppDimens.scrollPaddingTop,
              bottom: AppDimens.scrollPaddingBottom,
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
          FepleAppBar("채팅방"),
        ],
      ),
    );
  }
}
