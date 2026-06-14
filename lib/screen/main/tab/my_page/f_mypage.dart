import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/screen/main/tab/my_page/w_festival_certification.dart';
import 'package:feple/screen/main/tab/my_page/w_my_post_comment.dart';
import 'package:feple/screen/main/tab/my_page/w_my_song_requests.dart';
import 'package:feple/screen/main/tab/my_page/w_profile.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/screen/settings/s_settings.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MypageFragment extends StatefulWidget {
  const MypageFragment({super.key});

  @override
  State<MypageFragment> createState() => _MypageFragmentState();
}

class _MypageFragmentState extends State<MypageFragment> {
  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
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
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: RefreshIndicator(
                color: colors.activate,
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
                  child: Column(
                    children: [
                      ProfileWidget(key: ValueKey('profile_$_refreshKey'), userId: userId),
                      MyPostCommentWidget(key: ValueKey('stats_$_refreshKey'), userId: userId),
                      FtvCertificationWidget(key: ValueKey('cert_$_refreshKey')),
                      SongRequestHistoryWidget(key: ValueKey('songs_$_refreshKey')),
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
      icon: const Icon(Icons.settings_rounded, color: Colors.white),
      onPressed: () => Navigator.push(
        context,
        SlideRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}
