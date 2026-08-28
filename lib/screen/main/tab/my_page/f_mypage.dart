import 'package:feple/common/app_events.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/widget/w_adaptive_refresh_view.dart';
import 'package:feple/screen/main/tab/my_page/w_festival_certification.dart';
import 'package:feple/screen/main/tab/my_page/w_festival_diary.dart';
import 'package:feple/screen/main/tab/my_page/w_my_post_comment.dart';
import 'package:feple/screen/main/tab/my_page/w_my_song_requests.dart';
import 'package:feple/screen/main/tab/my_page/w_profile.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/screen/settings/s_settings.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyPageFragment extends StatefulWidget {
  const MyPageFragment({super.key});

  @override
  State<MyPageFragment> createState() => _MyPageFragmentState();
}

class _MyPageFragmentState extends State<MyPageFragment> with NavigationGuard {
  final _refresh = RefreshCoordinator();

  @override
  void initState() {
    super.initState();
    AppEvents.appResumed.addListener(_onAppResumed);
  }

  @override
  void dispose() {
    AppEvents.appResumed.removeListener(_onAppResumed);
    super.dispose();
  }

  void _onAppResumed() => unawaited(_onRefresh());

  Future<void> _onRefresh() => _refresh.refreshAll();

  @override
  Widget build(BuildContext context) {
    context.locale; // Subscribe to locale changes so labels re-translate immediately
    // userId만 구독 — 프로필 사진·닉네임 변경 시 이 위젯은 재빌드하지 않음
    final userId = context.select<UserProvider, int?>((p) => p.currentUserId);
    final colors = context.appColors;

    return ColoredBox(
      color: colors.backgroundMain,
      child: Column(
        children: [
          FepleAppBar(
            'Feple',
            extraTrailingActions: [_buildSettingsButton(context)],
          ),
          if (userId == null)
            Expanded(child: Center(child: CircularProgressIndicator(color: colors.activate)))
          else
            Expanded(
              child: AdaptiveRefreshView(
                indicatorColor: colors.activate,
                onRefresh: _onRefresh,
                padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
                child: RefreshScope(
                  coordinator: _refresh,
                  child: Column(
                    children: [
                      ProfileWidget(userId: userId),
                      MyPostCommentView(userId: userId),
                      const FestivalCertificationWidget(),
                      const FestivalDiaryWidget(),
                      const MySongRequestsView(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      tooltip: 'settings'.tr(),
      icon: Icon(Icons.settings_rounded, color: context.appColors.appBarIconColor),
      onPressed: () => guardedNavigate(() =>
          Navigator.push(context, SlideRoute(builder: (_) => const SettingsScreen()))),
    );
  }
}
