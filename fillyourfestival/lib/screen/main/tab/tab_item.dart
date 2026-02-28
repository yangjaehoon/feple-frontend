import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/screen/main/tab/chat/f_chat.dart';
import 'package:fast_app_base/screen/main/tab/community_board/f_community_board.dart';
import 'package:fast_app_base/screen/main/tab/concert_list/f_concert_list.dart';
import 'package:fast_app_base/screen/main/tab/home/f_home.dart';
import 'package:flutter/material.dart';
import 'my_page/f_mypage.dart';

enum TabItem {
  home(Icons.home_rounded, '홈', HomeFragment(), inActiveIcon: Icons.home_outlined),
  chat(Icons.chat_bubble_rounded, '채팅', ChatFragment(), inActiveIcon: Icons.chat_bubble_outline_rounded),
  concertList(Icons.music_note_rounded, '콘서트', ConcertListFragment(), inActiveIcon: Icons.music_note_outlined),
  communityBoard(Icons.forum_rounded, '게시판', CommunityBoardFragment(), inActiveIcon: Icons.forum_outlined),
  favorite(Icons.person_rounded, '마이', MypageFragment(), inActiveIcon: Icons.person_outline_rounded);

  final IconData activeIcon;
  final IconData inActiveIcon;
  final String tabName;
  final Widget firstPage;

  const TabItem(this.activeIcon, this.tabName, this.firstPage,
      {IconData? inActiveIcon})
      : inActiveIcon = inActiveIcon ?? activeIcon;

  BottomNavigationBarItem toNavigationBarItem(BuildContext context,
      {required bool isActivated}) {
    return BottomNavigationBarItem(
        icon: Icon(
          key: ValueKey(tabName),
          isActivated ? activeIcon : inActiveIcon,
          color: isActivated
              ? AppColors.skyBlue
              : AppColors.textMuted,
        ),
        label: tabName);
  }
}
