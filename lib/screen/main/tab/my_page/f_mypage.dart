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
  final _profileKey = GlobalKey<ProfileWidgetState>();
  final _statsKey = GlobalKey<MyPostCommentWidgetState>();
  final _certKey = GlobalKey<FtvCertificationWidgetState>();
  final _songsKey = GlobalKey<SongRequestHistoryWidgetState>();
  bool _isNavigating = false;

  Future<void> _onRefresh() async {
    _profileKey.currentState?.refresh();
    _statsKey.currentState?.refresh();
    _certKey.currentState?.refresh();
    _songsKey.currentState?.refresh();
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
            Expanded(child: Center(child: CircularProgressIndicator(color: colors.activate)))
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
                      ProfileWidget(key: _profileKey, userId: userId),
                      MyPostCommentWidget(key: _statsKey, userId: userId),
                      FtvCertificationWidget(key: _certKey),
                      SongRequestHistoryWidget(key: _songsKey),
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
      icon: Icon(Icons.settings_rounded, color: Theme.of(context).colorScheme.onPrimary),
      onPressed: () {
        if (_isNavigating) return;
        _isNavigating = true;
        Navigator.push(context, SlideRoute(builder: (_) => const SettingsScreen()))
            .whenComplete(() { if (mounted) _isNavigating = false; });
      },
    );
  }
}
