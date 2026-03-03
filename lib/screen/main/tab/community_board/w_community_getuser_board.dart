import 'package:fast_app_base/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class GetUserBoard extends StatelessWidget {
  final String boardname;

  const GetUserBoard({super.key, required this.boardname});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      title: '동행구하기 게시판',
      icon: Icons.people_rounded,
      headerColorFn: (colors) => colors.getUserBoardHeader,
      serviceBoardType: 'MateBoard',
      boardname: 'GetuserBoard',
    );
  }
}
