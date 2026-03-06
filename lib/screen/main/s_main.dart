import 'package:after_layout/after_layout.dart';
import 'package:fast_app_base/common/cli_common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/login/login.dart';
import 'package:fast_app_base/screen/main/tab/tab_item.dart';
import 'package:fast_app_base/screen/main/tab/tab_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../../common/common.dart';
import '../../provider/poster/poster_provider.dart';
import 'w_menu_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});


  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin{
  TabItem _currentTab = TabItem.home;
  final Set<int> _visitedTabs = {};
  final tabs = [
    TabItem.search,
    TabItem.communityBoard,
    TabItem.home,
    TabItem.concertList,
    TabItem.favorite,
  ];
  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  int get _currentIndex => tabs.indexOf(_currentTab);

  GlobalKey<NavigatorState> get _currentTabNavigationKey =>
      navigatorKeys[_currentIndex];

  bool get extendBody => true;

  static double get bottomNavigationBarBorderRadius => 30.0;

  @override
  void initState() {
    super.initState();
    _visitedTabs.add(tabs.indexOf(TabItem.home));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = _currentTabNavigationKey.currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else if (_currentTab != TabItem.home) {
          _changeTab(tabs.indexOf(TabItem.home));
        }
      },
      child: Scaffold(
        extendBody: extendBody,
        drawer: const MenuDrawer(),
        body: Container(
          color: context.appColors.backgroundMain,
          padding: EdgeInsets.only(
              bottom: extendBody ? 60 - bottomNavigationBarBorderRadius : 0),
          child: SafeArea(
            bottom: !extendBody,
            child: pages,
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  Widget get pages => IndexedStack(
      index: _currentIndex,
      children: tabs
          .mapIndexed((tab, index) => Offstage(
                offstage: _currentTab != tab,
                child: _visitedTabs.contains(index)
                    ? TabNavigator(
                        navigatorKey: navigatorKeys[index],
                        tabItem: tab,
                      )
                    : const SizedBox.shrink(),
              ))
          .toList());



  Widget _buildBottomNavigationBar(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bottomNavBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(bottomNavigationBarBorderRadius),
          topRight: Radius.circular(bottomNavigationBarBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.bottomNavShadow.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(bottomNavigationBarBorderRadius),
          topRight: Radius.circular(bottomNavigationBarBorderRadius),
        ),
        child: BottomNavigationBar(
          items: navigationBarItems(context),
          currentIndex: _currentIndex,
          selectedItemColor: colors.activate,
          unselectedItemColor: colors.textSecondary,
          backgroundColor: colors.bottomNavBg,
          onTap: _handleOnTapNavigationBarItem,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> navigationBarItems(BuildContext context) {
    return tabs
        .mapIndexed(
          (tab, index) => tab.toNavigationBarItem(
            context,
            isActivated: _currentIndex == index,
          ),
        )
        .toList();
  }

  void _changeTab(int index) {
    setState(() {
      _visitedTabs.add(index);
      _currentTab = tabs[index];
    });
  }

  BottomNavigationBarItem bottomItem(bool activate, IconData iconData,
      IconData inActivateIconData, String label) {
    final colors = context.appColors;
    return BottomNavigationBarItem(
        icon: Icon(
          key: ValueKey(label),
          activate ? iconData : inActivateIconData,
          color: activate
              ? colors.activate
              : colors.textSecondary,
        ),
        label: label);
  }

  void _handleOnTapNavigationBarItem(int index) {
    if (tabs[index] == _currentTab) {
      popAllHistory(navigatorKeys[index]);
    }
    _changeTab(index);
  }

  void popAllHistory(GlobalKey<NavigatorState> navigationKey) {
    final bool canPop = navigationKey.currentState?.canPop() == true;
    if (canPop) {
      while (navigationKey.currentState?.canPop() == true) {
        navigationKey.currentState!.pop();
      }
    }
  }

}
