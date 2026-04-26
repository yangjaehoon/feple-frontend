import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/screen/main/tab/my_page/w_follow_artists.dart';
import 'package:feple/screen/main/tab/my_page/w_festival_certification.dart';
import 'package:feple/screen/main/tab/my_page/w_my_post_comment.dart';
import 'package:feple/screen/main/tab/my_page/w_profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../provider/user_provider.dart';
import '../search/w_feple_app_bar.dart';

class MypageFragment extends StatefulWidget {
  const MypageFragment({super.key});

  @override
  State<MypageFragment> createState() => _MypageFragmentState();
}

class _MypageFragmentState extends State<MypageFragment> {
  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
    // 자식 위젯이 재생성되어 데이터를 재로드할 시간을 줌
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    // userId만 구독 — 프로필 사진·닉네임 변경 시 이 위젯은 재빌드하지 않음
    final userId = context.select<UserProvider, int?>((p) => p.user?.id);
    final rs = ResponsiveSize(context);

    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: context.appColors.backgroundMain,
      child: Stack(
        children: [
          RefreshIndicator(
            color: context.appColors.activate,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: rs.h(AppDimens.scrollPaddingTop),
                bottom: rs.h(AppDimens.scrollPaddingBottom),
              ),
              child: Column(
                children: [
                  ProfileWidget(key: ValueKey('profile_$_refreshKey'), userId: userId),
                  MyPostCommentWidget(userId: userId),
                  FtvCertificationWidget(key: ValueKey('cert_$_refreshKey')),
                  FollowArtistsWidget(key: ValueKey('follow_$_refreshKey'), userId: userId),
                ],
              ),
            ),
          ),
          const FepleAppBar("Feple"),
        ],
      ),
    );
  }
}
