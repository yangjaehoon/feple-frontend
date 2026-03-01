import 'package:fast_app_base/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class HotBoard extends StatelessWidget {
  final String boardname;

  const HotBoard({super.key, required this.boardname});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      title: '인기 게시판',
      icon: Icons.local_fire_department_rounded,
      headerColorFn: (colors) => colors.hotBoardHeader,
      serviceBoardType: 'HotBoard',
      boardname: 'HotBoard',
    );
  }
}
