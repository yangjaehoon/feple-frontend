import 'package:feple/common/common.dart';
import 'package:feple/screen/main/tab/home/f_home.dart';
import 'package:feple/screen/main/tab/community_board/f_community_board.dart';
import 'package:feple/screen/main/tab/festival_list/f_festival_list.dart';
import 'package:feple/screen/main/tab/search/f_search.dart';
import 'package:flutter/material.dart';
import 'my_page/f_mypage.dart';

enum TabItem {
  search(Icons.search_rounded, 'tab_search', SearchFragment(),
      inActiveIcon: Icons.search_outlined),
  home(Icons.home_rounded, 'tab_home', HomeFragment(),
      inActiveIcon: Icons.home_outlined),
  concertList(Icons.queue_music_rounded, 'tab_concert', ConcertListFragment(),
      inActiveIcon: Icons.queue_music_outlined),
  communityBoard(Icons.forum_rounded, 'tab_board', CommunityBoardFragment(),
      inActiveIcon: Icons.forum_outlined),
  favorite(Icons.person_rounded, 'tab_my', MypageFragment(),
      inActiveIcon: Icons.person_outlined);

  final IconData activeIcon;
  final IconData inActiveIcon;
  final String tabNameKey;
  final Widget firstPage;

  const TabItem(this.activeIcon, this.tabNameKey, this.firstPage,
      {IconData? inActiveIcon})
      : inActiveIcon = inActiveIcon ?? activeIcon;

  String get tabName => tabNameKey.tr();

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: Icon(inActiveIcon, size: 24),
      selectedIcon: Icon(activeIcon, size: 24),
      label: tabName,
    );
  }
}
