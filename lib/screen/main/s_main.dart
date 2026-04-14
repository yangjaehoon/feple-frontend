import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:feple/screen/main/tab/tab_navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/common.dart';
import '../../provider/post_change_notifier.dart';
import 'w_menu_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  TabItem _currentTab = TabItem.home;
  final Set<int> _visitedTabs = {};
  final tabs = [
    TabItem.search,
    TabItem.communityBoard,
    TabItem.home,
    TabItem.concertList,
    TabItem.favorite,
  ];
  final List<GlobalKey<NavigatorState>> navigatorKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  bool _showBottomNav = true;

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

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 3 && _showBottomNav) {
        setState(() => _showBottomNav = false);
      } else if (delta < -3 && !_showBottomNav) {
        setState(() => _showBottomNav = true);
      }
    }
    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0) {
        setState(() => _showBottomNav = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = _showBottomNav
        ? (extendBody ? 60 - bottomNavigationBarBorderRadius : 0.0)
        : MediaQuery.of(context).padding.bottom;

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
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          color: context.appColors.backgroundMain,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SafeArea(
            bottom: !extendBody,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: pages,
            ),
          ),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(bottomNavigationBarBorderRadius),
            topRight: Radius.circular(bottomNavigationBarBorderRadius),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            heightFactor: _showBottomNav ? 1.0 : 0.0,
            child: _buildBottomNavigationBar(context),
          ),
        ),
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
        boxShadow: [
          BoxShadow(
            color: colors.bottomNavShadow.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
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
      _showBottomNav = true; // 탭 전환 시 항상 하단바 표시
    });
  }

  BottomNavigationBarItem bottomItem(bool activate, IconData iconData,
      IconData inActivateIconData, String label) {
    final colors = context.appColors;
    return BottomNavigationBarItem(
        icon: Icon(
          key: ValueKey(label),
          activate ? iconData : inActivateIconData,
          color: activate ? colors.activate : colors.textSecondary,
        ),
        label: label);
  }

  void _handleOnTapNavigationBarItem(int index) {
    if (tabs[index] == _currentTab) {
      popAllHistory(navigatorKeys[index]);
    }
    if (tabs[index] == TabItem.communityBoard) {
      context.read<PostChangeNotifier>().notifyPostChanged();
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
