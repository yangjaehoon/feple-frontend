import 'package:fast_app_base/screen/main/tab/my_page/w_follow_artists.dart';
import 'package:fast_app_base/screen/main/tab/my_page/w_ftv_certification.dart';
import 'package:fast_app_base/screen/main/tab/my_page/w_my_post_comment.dart';
import 'package:fast_app_base/screen/main/tab/my_page/w_profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fast_app_base/screen/main/tab/my_page/d_myinformation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home/w_fyf_app_bar.dart';

class MypageFragment extends StatefulWidget {
  const MypageFragment({super.key});

  @override
  State<MypageFragment> createState() => _MypageFragmentState();
}

class _MypageFragmentState extends State<MypageFragment> {
  Future<MyInfo> fetchUser() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final response = await http.get(
      Uri.parse('http://13.209.108.218:8080/users/getuser?id=$uid'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return MyInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<MyInfo> myinfo = fetchUser();

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
                ProfileWidget(myInfo: myinfo), // Todo nickname, level 2개 넘겨주기
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
