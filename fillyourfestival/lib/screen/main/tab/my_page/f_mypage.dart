import 'package:fast_app_base/screen/main/tab/my_page/w_follow_artists.dart';
import 'package:fast_app_base/screen/main/tab/my_page/w_ftv_certification.dart';
import 'package:fast_app_base/screen/main/tab/my_page/w_my_post_comment.dart';
import 'package:fast_app_base/screen/main/tab/my_page/w_profile.dart';
import 'package:flutter/material.dart';
import '../home/w_fyf_app_bar.dart';

class MypageFragment extends StatefulWidget {
  const MypageFragment({super.key});

  @override
  State<MypageFragment> createState() => _MypageFragmentState();
}

class _MypageFragmentState extends State<MypageFragment> {


  @override
  Widget build(BuildContext context) {

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 50,
            ), // 상단바 부분만큼 띄워줌(stack이여서),
            child: Column(
              children: [
                ProfileWidget(), // Todo nickname, level 2개 넘겨주기
                MyPostCommentWidget(), // Todo post_num, comment_num, bookmark_num 3개 넘겨주기
                FtvCertificationWidget(), 
                FollowArtistsWidget(), // Todo follow_artist 넘겨주기
              ],
            ),
          ),
          //CircleArtistWidget(),
          FyfAppBar("Fill your Festival"),
        ],
      ),
    );
  }
}
