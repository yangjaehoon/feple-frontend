import 'package:feple/common/app_events.dart';
import 'package:feple/model/post_changed_event.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/community_board/w_community_hot_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_free_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_companion_board.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';

class CommunityBoardFragment extends StatelessWidget {
  const CommunityBoardFragment({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      color: colors.backgroundMain,
      child: Column(
        children: [
          FepleAppBar('board'.tr()),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: () async {
                AppEvents.postChanged.value = PostChangedEvent.refreshAll();
                // 하위 보드가 이벤트를 받아 리로드하는 시간 확보
                await Future.delayed(const Duration(milliseconds: 1200));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: AppDimens.scrollPaddingBottomLarge),
                  child: Column(
                    children: [
                      HotBoard(),
                      FreeBoard(),
                      GetUserBoard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
