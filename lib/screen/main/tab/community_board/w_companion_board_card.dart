import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:flutter/material.dart';

class CompanionBoardCard extends StatelessWidget {
  final GlobalKey<CommunityBoardCardState>? cardKey;

  const CompanionBoardCard({super.key, this.cardKey});

  @override
  Widget build(BuildContext context) {
    return CommunityBoardCard(
      key: cardKey,
      title: 'companion_board'.tr(),
      icon: Icons.people_rounded,
      headerColorFn: (colors) => colors.getUserBoardHeader,
      serviceBoardType: BoardTypes.mate,
      boardName: 'companion_board'.tr(),
    );
  }
}
