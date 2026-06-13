import 'package:feple/common/app_events.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/community_board/w_community_hot_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_free_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_companion_board.dart';
import 'package:flutter/material.dart';

class CommunityBoardFragment extends StatelessWidget {
  const CommunityBoardFragment({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.backgroundMain,
      child: RefreshIndicator(
        color: context.appColors.activate,
        onRefresh: () async {
          AppEvents.postChanged.value++;
          await Future.delayed(AppDimens.animRefresh);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: AppDimens.scrollPaddingBottomLarge,
            ),
            child: const Column(
              children: [
                HotBoard(),
                FreeBoard(),
                GetUserBoard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
