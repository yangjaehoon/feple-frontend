import 'package:easy_localization/easy_localization.dart';
import 'package:feple/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class FreeBoard extends StatelessWidget {
  final String boardname;

  const FreeBoard({super.key, required this.boardname});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      title: 'free_board'.tr(),
      icon: Icons.edit_note_rounded,
      headerColorFn: (colors) => colors.freeBoardHeader,
      serviceBoardType: 'FreeBoard',
      boardname: 'FreeBoard',
    );
  }
}
