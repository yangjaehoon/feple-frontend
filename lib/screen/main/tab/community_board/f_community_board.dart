import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/screen/main/tab/community_board/w_community_hot_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_free_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_getuser_board.dart';
import 'package:flutter/material.dart';

class CommunityBoardFragment extends StatelessWidget {
  const CommunityBoardFragment({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    return Container(
      color: context.appColors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: rs.h(AppDimens.scrollPaddingTop),
                bottom: rs.h(AppDimens.scrollPaddingBottomLarge),
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
          FepleAppBar('board'.tr()),
        ],
      ),
    );
  }
}
