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

  @override
  Widget build(BuildContext context) {
    final me = context.watch<UserProvider>().user;
    final rs = ResponsiveSize(context);

    if (me == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      color: context.appColors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: rs.h(AppDimens.scrollPaddingTop),
              bottom: rs.h(AppDimens.scrollPaddingBottom),
            ),
            child: Column(
              children: [
                ProfileWidget(userId: me.id,),
                MyPostCommentWidget(userId: me.id),
                FtvCertificationWidget(),
                FollowArtistsWidget(userId: me.id),
              ],
            ),
          ),
          FepleAppBar("Feple"),
        ],
      ),
    );
  }
}
