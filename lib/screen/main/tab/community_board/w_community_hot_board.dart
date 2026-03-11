import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class HotBoard extends StatelessWidget {
  final String boardname;

  const HotBoard({super.key, required this.boardname});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      title: 'hot_board'.tr(),
      icon: Icons.local_fire_department_rounded,
      headerColorFn: (colors) => colors.hotBoardHeader,
      serviceBoardType: 'HotBoard',
      boardname: 'HotBoard',
    );
  }
}
