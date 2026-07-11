import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class CommunityFreeBoard extends StatelessWidget {
  final GlobalKey<CommunityBoardCardState>? cardKey;

  const CommunityFreeBoard({super.key, this.cardKey});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      key: cardKey,
      title: 'free_board'.tr(),
      icon: Icons.edit_note_rounded,
      headerColorFn: (colors) => colors.freeBoardHeader,
      serviceBoardType: BoardTypes.free,
      boardName: 'free_board'.tr(),
    );
  }
}
