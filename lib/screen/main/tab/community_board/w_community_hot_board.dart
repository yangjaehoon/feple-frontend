import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class CommunityHotBoard extends StatelessWidget {
  final GlobalKey<CommunityBoardCardState>? cardKey;

  const CommunityHotBoard({super.key, this.cardKey});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      key: cardKey,
      title: 'hot_board'.tr(),
      icon: Icons.local_fire_department_rounded,
      headerColorFn: (colors) => colors.hotBoardHeader,
      serviceBoardType: BoardTypes.hot,
      boardName: 'hot_board'.tr(),
      showWriteButton: false,
      emptyHint: 'hot_board_empty'.tr(),
    );
  }
}
