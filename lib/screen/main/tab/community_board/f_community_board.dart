import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_hot_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_free_board.dart';
import 'package:feple/screen/main/tab/community_board/w_companion_board_card.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';

class CommunityBoardFragment extends StatefulWidget {
  const CommunityBoardFragment({
    super.key,
  });

  @override
  State<CommunityBoardFragment> createState() => _CommunityBoardFragmentState();
}

class _CommunityBoardFragmentState extends State<CommunityBoardFragment> {
  final _hotKey = GlobalKey<CommunityBoardCardState>();
  final _freeKey = GlobalKey<CommunityBoardCardState>();
  final _companionKey = GlobalKey<CommunityBoardCardState>();

  // 실제 세 게시판의 refresh()가 끝날 때까지 기다려 당겨서 새로고침 스피너가
  // 데이터 갱신 완료와 맞물려 사라지도록 함 — 예전엔 전역 이벤트만 던지고
  // Future.delayed(고정 시간)로 "이 정도면 끝났겠지" 하고 넘어갔었음
  Future<void> _onRefresh() async {
    await Future.wait([
      _hotKey.currentState?.refresh() ?? Future.value(),
      _freeKey.currentState?.refresh() ?? Future.value(),
      _companionKey.currentState?.refresh() ?? Future.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Subscribe to locale changes so AppBar title re-translates immediately
    final colors = context.appColors;
    return ColoredBox(
      color: colors.backgroundMain,
      child: Column(
        children: [
          FepleAppBar('board'.tr()),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottomLarge),
                  child: Column(
                    children: [
                      CommunityHotBoard(cardKey: _hotKey),
                      CommunityFreeBoard(cardKey: _freeKey),
                      CompanionBoardCard(cardKey: _companionKey),
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
