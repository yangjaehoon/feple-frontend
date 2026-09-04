import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_require_login_gate.dart';
import 'package:feple/screen/main/tab/community_board/f_community_board.dart';
import 'package:feple/screen/main/tab/festival_list/f_festival_list.dart';
import 'package:feple/screen/main/tab/home/f_home.dart';
import 'package:feple/screen/main/tab/my_page/f_mypage.dart';
import 'package:feple/screen/main/tab/search/f_search.dart';
import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('TabItem.firstPage', () {
    test('비계정 탭(검색·페스티벌 목록)은 게스트도 바로 접근 가능해 로그인 게이트로 감싸지 않는다', () {
      expect(TabItem.search.firstPage, isA<SearchFragment>());
      expect(TabItem.festivalList.firstPage, isA<FestivalListFragment>());
    });

    test('홈·커뮤니티는 RequireLoginGate로 감싸 게스트를 막는다', () {
      expect(TabItem.communityBoard.firstPage, isA<RequireLoginGate>());
      expect(TabItem.home.firstPage, isA<RequireLoginGate>());

      expect(
        (TabItem.communityBoard.firstPage as RequireLoginGate).child,
        isA<CommunityBoardFragment>(),
      );
      expect(
        (TabItem.home.firstPage as RequireLoginGate).child,
        isA<HomeFragment>(),
      );
    });

    test('마이페이지는 게이트로 감싸지 않는다 — MyPageFragment가 직접 게스트 뷰를 그린다', () {
      expect(TabItem.favorite.firstPage, isA<MyPageFragment>());
    });
  });

  group('TabItem.tabName', () {
    test('탭 이름 키를 i18n으로 변환한다', () {
      expect(TabItem.search.tabName, 'tab_search'.tr());
      expect(TabItem.home.tabName, 'tab_home'.tr());
    });
  });

  group('TabItem.appbarTitle', () {
    test('커뮤니티 게시판은 board 타이틀을 사용한다', () {
      expect(TabItem.communityBoard.appbarTitle, 'board'.tr());
    });

    test('페스티벌 목록은 festival_schedule 타이틀을 사용한다', () {
      expect(TabItem.festivalList.appbarTitle, 'festival_schedule'.tr());
    });

    test('그 외 탭은 Feple을 기본 타이틀로 사용한다', () {
      expect(TabItem.search.appbarTitle, 'Feple');
      expect(TabItem.home.appbarTitle, 'Feple');
      expect(TabItem.favorite.appbarTitle, 'Feple');
    });
  });

  group('TabItem.toNavigationDestination', () {
    test('활성/비활성 아이콘과 라벨을 포함한 NavigationDestination을 생성한다', () {
      final destination = TabItem.search.toNavigationDestination();

      expect(destination.label, 'tab_search'.tr());
      expect((destination.icon as Icon).icon, Icons.search_outlined);
      expect((destination.selectedIcon as Icon).icon, Icons.search_rounded);
    });

    test('inActiveIcon을 지정하지 않으면 activeIcon과 같다', () {
      final destination = TabItem.home.toNavigationDestination();

      expect((destination.icon as Icon).icon, Icons.home_outlined);
    });
  });
}
