import 'package:fast_app_base/common/common.dart';
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
                top: 60,
                bottom: 100,
              ), // 상단바 부분만큼 띄워줌(stack이여서),
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

  void showSnackbar(BuildContext context) {
    context.showSnackbar('snackbar 입니다.',
        extraButton: Tap(
          onTap: () {
            context.showErrorSnackbar('error');
          },
          child: '에러 보여주기 버튼'
              .text
              .white
              .size(13)
              .make()
              .centered()
              .pSymmetric(h: 10, v: 5),
        ));
  }

  void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}
