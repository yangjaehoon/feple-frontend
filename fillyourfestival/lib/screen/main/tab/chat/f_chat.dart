import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
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
    final rs = ResponsiveSize(context);
    return Container(
      color: context.appColors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: rs.h(AppDimens.scrollPaddingTop),
              bottom: rs.h(AppDimens.scrollPaddingBottom),
            ),
            child: const Column(
              children: [
                //TodayFtvChat(),
                //MyChat(),
                //FanChat(),
              ],
            ),
          ),
          FepleAppBar("채팅방"),
        ],
      ),
    );
  }
}
