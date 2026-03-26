import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/screen/main/tab/home/f_home.dart';
import 'package:fast_app_base/screen/main/tab/community_board/f_community_board.dart';
import 'package:fast_app_base/screen/main/tab/concert_list/f_concert_list.dart';
import 'package:fast_app_base/screen/main/tab/search/f_search.dart';
import 'package:flutter/material.dart';
import 'my_page/f_mypage.dart';

enum TabItem {
  search(Icons.search_rounded, 'tab_search', SearchFragment(),
      inActiveIcon: Icons.search_outlined),
  home(Icons.home_rounded, 'tab_home', HomeFragment(),
      inActiveIcon: Icons.home_outlined),
  concertList(Icons.music_note_rounded, 'tab_concert', ConcertListFragment(),
      inActiveIcon: Icons.music_note_outlined),
  communityBoard(Icons.forum_rounded, 'tab_board', CommunityBoardFragment(),
      inActiveIcon: Icons.forum_outlined),
  favorite(Icons.person_rounded, 'tab_my', MypageFragment(),
      inActiveIcon: Icons.person_outline_rounded);

  final IconData activeIcon;
  final IconData inActiveIcon;
  final String tabNameKey;
  final Widget firstPage;

  const TabItem(this.activeIcon, this.tabNameKey, this.firstPage,
      {IconData? inActiveIcon})
      : inActiveIcon = inActiveIcon ?? activeIcon;

  String get tabName => tabNameKey.tr();

  BottomNavigationBarItem toNavigationBarItem(BuildContext context,
      {required bool isActivated}) {
    final colors = context.appColors;
    return BottomNavigationBarItem(
        icon: Icon(
          key: ValueKey(tabName),
          isActivated ? activeIcon : inActiveIcon,
          color: isActivated ? colors.activate : colors.textSecondary,
        ),
        label: tabName);
  }
}
