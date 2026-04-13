import 'package:easy_localization/easy_localization.dart';
import 'package:feple/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class GetUserBoard extends StatelessWidget {
  final String boardname;

  const GetUserBoard({super.key, required this.boardname});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      title: 'companion_board'.tr(),
      icon: Icons.people_rounded,
      headerColorFn: (colors) => colors.getUserBoardHeader,
      serviceBoardType: 'MateBoard',
      boardname: 'GetuserBoard',
    );
  }
}
