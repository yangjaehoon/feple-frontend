import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/screen/dialog/d_message.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_app_bar.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_hot_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_free_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_getuser_board.dart';
import 'package:flutter/material.dart';

import '../../../dialog/d_color_bottom.dart';
import '../../../dialog/d_confirm.dart';

class CommunityBoardFragment extends StatelessWidget {
  const CommunityBoardFragment({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      color: AppColors.backgroundLight,
      child: const Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: 60,
                bottom: 40,
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
          CommunityBoardAppBar(),
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

  Future<void> showConfirmDialog(BuildContext context) async {
    final confirmDialogResult = await ConfirmDialog(
      '오늘 기분이 좋나요?',
      buttonText: "네",
      cancelButtonText: "아니오",
    ).show();
    debugPrint(confirmDialogResult?.isSuccess.toString());

    confirmDialogResult?.runIfSuccess((data) {
      ColorBottomSheet(
        '❤️',
        context: context,
        backgroundColor: Colors.yellow.shade200,
      ).show();
    });

    confirmDialogResult?.runIfFailure((data) {
      ColorBottomSheet(
        '❤️힘내여',
        backgroundColor: Colors.yellow.shade300,
        textColor: Colors.redAccent,
      ).show();
    });
  }

  Future<void> showMessageDialog() async {
    final result = await MessageDialog("안녕하세요").show();
    debugPrint(result.toString());
  }

  void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}
