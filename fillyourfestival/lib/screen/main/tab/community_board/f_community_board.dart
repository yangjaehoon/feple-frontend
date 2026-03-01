import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/screen/main/tab/home/w_feple_app_bar.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_hot_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_free_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_getuser_board.dart';
import 'package:flutter/material.dart';

class CommunityBoardFragment extends StatelessWidget {
  const CommunityBoardFragment({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.backgroundMain,
      child: const Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppDimens.scrollPaddingTop,
                bottom: AppDimens.scrollPaddingBottomLarge,
              ),
              child: Column(
                children: [
                  HotBoard(boardname: "HotBoard"),
                  FreeBoard(boardname: "FreeBoard"),
                  GetUserBoard(boardname: "GetuserBoard"),
                ],
              ),
            ),
          ),
          FepleAppBar("게시판"),
        ],
      ),
    );
  }
}
