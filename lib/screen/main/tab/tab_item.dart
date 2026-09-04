import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_require_login_gate.dart';
import 'package:feple/screen/main/tab/home/f_home.dart';
import 'package:feple/screen/main/tab/community_board/f_community_board.dart';
import 'package:feple/screen/main/tab/festival_list/f_festival_list.dart';
import 'package:feple/screen/main/tab/search/f_search.dart';
import 'package:flutter/material.dart';
import 'my_page/f_mypage.dart';

// 선언 순서 = 하단 탭 바 실제 표시 순서 (MainScreenState.tabs와 반드시 일치시킬 것)
// 홈·커뮤니티는 계정 기반 탭이라 RequireLoginGate로 감싸 게스트에게는 로그인 유도
// 화면을 보여준다. 마이페이지는 게스트에게 로그인 CTA + 고객센터·약관·방침을
// 보여줘야 해서 MyPageFragment가 직접 게스트 뷰를 그린다. 검색·페스티벌 목록은
// 비계정 콘텐츠라 게스트도 바로 접근 가능하다 (Apple 가이드라인 5.1.1(v)).
enum TabItem {
  search(Icons.search_rounded, 'tab_search', SearchFragment(),
      inActiveIcon: Icons.search_outlined),
  communityBoard(
      Icons.forum_rounded,
      'tab_board',
      RequireLoginGate(
        icon: Icons.forum_outlined,
        titleKey: 'guest_login_title_board',
        messageKey: 'guest_login_required_board',
        child: CommunityBoardFragment(),
      ),
      inActiveIcon: Icons.forum_outlined),
  home(
      Icons.home_rounded,
      'tab_home',
      RequireLoginGate(
        icon: Icons.home_outlined,
        titleKey: 'guest_login_title_home',
        messageKey: 'guest_login_required_home',
        child: HomeFragment(),
      ),
      inActiveIcon: Icons.home_outlined),
  festivalList(Icons.queue_music_rounded, 'tab_concert', FestivalListFragment(),
      inActiveIcon: Icons.queue_music_outlined),
  favorite(Icons.person_rounded, 'tab_my', MyPageFragment(),
      inActiveIcon: Icons.person_outlined);

  final IconData activeIcon;
  final IconData inActiveIcon;
  final String tabNameKey;
  final Widget firstPage;

  const TabItem(this.activeIcon, this.tabNameKey, this.firstPage,
      {IconData? inActiveIcon})
      : inActiveIcon = inActiveIcon ?? activeIcon;

  String get tabName => tabNameKey.tr();

  String get appbarTitle => switch (this) {
    TabItem.communityBoard => 'board'.tr(),
    TabItem.festivalList    => 'festival_schedule'.tr(),
    _                      => 'Feple',
  };

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: Icon(inActiveIcon, size: 24),
      selectedIcon: Icon(activeIcon, size: 24),
      label: tabName,
    );
  }
}
