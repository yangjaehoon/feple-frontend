import 'package:feple/app.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/widget/w_adaptive_refresh_view.dart';
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
  final _refresh = RefreshCoordinator();

  @override
  void initState() {
    super.initState();
    App.resumeEvent.addListener(_onAppResumed);
  }

  @override
  void dispose() {
    App.resumeEvent.removeListener(_onAppResumed);
    super.dispose();
  }

  void _onAppResumed() => unawaited(_onRefresh());

  // 세 게시판의 로드가 실제로 끝날 때까지 기다려 당겨서 새로고침 스피너가
  // 데이터 갱신 완료와 맞물려 사라지도록 함.
  Future<void> _onRefresh() => _refresh.refreshAll();

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
            child: AdaptiveRefreshView(
              indicatorColor: colors.activate,
              onRefresh: _onRefresh,
              padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottomLarge),
              child: RefreshScope(
                coordinator: _refresh,
                child: const Column(
                  children: [
                    CommunityHotBoard(),
                    CommunityFreeBoard(),
                    CompanionBoardCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
