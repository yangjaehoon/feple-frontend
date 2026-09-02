import 'package:collection/collection.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_offline_banner.dart';
import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:feple/screen/main/tab/w_tab_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../common/app_events.dart';
import '../../model/post_changed_event.dart';
import '../../common/common.dart';
import '../../provider/user_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class _NavBarObserver extends NavigatorObserver {
  final VoidCallback onPop;
  _NavBarObserver(this.onPop);

  @override
  void didPop(Route route, Route? previousRoute) => onPop();
}

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  TabItem _currentTab = TabItem.home;
  final Set<int> _visitedTabs = {};
  // 하단 탭 바 표시 순서 = TabItem 선언 순서
  final tabs = TabItem.values;
  late final List<GlobalKey<NavigatorState>> navigatorKeys =
      List.generate(tabs.length, (_) => GlobalKey<NavigatorState>());
  late final List<_NavBarObserver> _tabObservers;

  final _showBottomNav = ValueNotifier<bool>(true);

  int get _currentIndex => tabs.indexOf(_currentTab);

  // 게스트에게 홈 탭은 로그인 유도 화면이라 로고 탭·뒤로가기 복귀 지점으로
  // 부적절함 — 비계정 탭인 페스티벌 목록으로 대신 보낸다. 로그인 상태는 탭
  // 전환 시점마다 새로 확인해, 게스트로 시작했다가 화면 안에서 로그인해도
  // (RequireLoginGate 경유) 곧바로 홈으로 정확히 돌아간다.
  TabItem get _landingTab =>
      Provider.of<UserProvider>(context, listen: false).user == null
          ? TabItem.festivalList
          : TabItem.home;

  GlobalKey<NavigatorState> get _currentTabNavigationKey =>
      navigatorKeys[_currentIndex];

  static const bool extendBody = true;

  static const double bottomNavigationBarBorderRadius = 30.0;

  @override
  void initState() {
    super.initState();
    // 게스트는 계정 기반 탭인 홈(팔로우 아티스트/좋아요 페스티벌)이 로그인 유도
    // 화면으로 막혀 있으므로, 비계정 콘텐츠인 페스티벌 목록 탭으로 시작한다.
    _currentTab = _landingTab;
    _visitedTabs.add(_currentIndex);
    _tabObservers = List.generate(
      tabs.length,
      (_) => _NavBarObserver(() {
        if (mounted) _showBottomNav.value = true;
      }),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      // 3px 미만은 잔떨림으로 간주해 무시 — 없으면 미세한 스크롤에도
      // 매 프레임 표시 상태가 깜빡임
      if (delta > 3 && _showBottomNav.value) {
        _showBottomNav.value = false;
      } else if (delta < -3 && !_showBottomNav.value) {
        _showBottomNav.value = true;
      }
    }
    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBottomNav.value = true;
        });
      }
    }
    return false;
  }

  @override
  void dispose() {
    _showBottomNav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Subscribe to locale changes so bottom nav labels re-translate immediately
    return OfflineBanner(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final navigator = _currentTabNavigationKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          } else if (_currentTab != _landingTab) {
            _changeTab(tabs.indexOf(_landingTab));
          } else {
            final confirmed = await showConfirmDialog(
              context,
              title: 'exit_app'.tr(),
              content: 'exit_app_confirm'.tr(),
              confirmLabel: 'confirm'.tr(),
            );
            if (confirmed) unawaited(SystemNavigator.pop());
          }
        },
        child: Scaffold(
          extendBody: extendBody,
          body: _buildAnimatedBody(),
          bottomNavigationBar: _buildAnimatedBottomNav(),
        ),
      ),
    );
  }

  // ValueListenableBuilder: 스크롤 이벤트 시 body 패딩만 재빌드.
  // child를 분리해 ValueNotifier 변경과 무관하게 탭 페이지는 한 번만 빌드.
  Widget _buildAnimatedBody() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showBottomNav,
      builder: (context, show, child) {
        final bottomPadding = show ? 0.0 : MediaQuery.paddingOf(context).bottom;
        return AnimatedContainer(
          duration: AppDimens.animFast,
          curve: Curves.easeInOut,
          color: context.appColors.backgroundMain,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: child!,
        );
      },
      child: SafeArea(
        bottom: !extendBody,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: pages,
        ),
      ),
    );
  }

  Widget _buildAnimatedBottomNav() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showBottomNav,
      builder: (context, show, _) => ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(bottomNavigationBarBorderRadius),
          topRight: Radius.circular(bottomNavigationBarBorderRadius),
        ),
        child: AnimatedAlign(
          duration: AppDimens.animFast,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          heightFactor: show ? 1.0 : 0.0,
          child: _buildBottomNavigationBar(context),
        ),
      ),
    );
  }

  Widget get pages => IndexedStack(
      index: _currentIndex,
      children: tabs
          .mapIndexed((index, tab) => Offstage(
                offstage: _currentTab != tab,
                child: _visitedTabs.contains(index)
                    ? TabNavigator(
                        navigatorKey: navigatorKeys[index],
                        tabItem: tab,
                        observers: [_tabObservers[index]],
                      )
                    : const SizedBox.shrink(),
              ))
          .toList());

  Widget _buildBottomNavigationBar(BuildContext context) {
    final colors = context.appColors;
    final systemBottomInset = MediaQuery.paddingOf(context).bottom;
    final double bottomInset = systemBottomInset
        .clamp(AppDimens.bottomNavMinInset, AppDimens.bottomNavMaxInset)
        .toDouble();
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
      // NavigationBar 내부 SafeArea가 시스템 하단 inset(iOS 홈 인디케이터 등)을
      // 그대로 더하는 것을 막고, clamp한 값만 하단 패딩으로 적용한다.
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _handleOnTapNavigationBarItem,
            destinations: navigationDestinations(),
            backgroundColor: colors.bottomNavBg,
            elevation: 0,
            height: AppDimens.bottomNavContentHeight,
            animationDuration: AppDimens.animQuick,
          ),
        ),
      ),
    );
  }

  List<NavigationDestination> navigationDestinations() {
    return tabs.map((tab) => tab.toNavigationDestination()).toList();
  }

  void goHome() {
    final homeIndex = tabs.indexOf(_landingTab);
    popAllHistory(navigatorKeys[homeIndex]);
    _changeTab(homeIndex);
  }

  void _changeTab(int index) {
    _showBottomNav.value = true; // 탭 전환 시 항상 하단바 표시
    setState(() {
      _visitedTabs.add(index);
      _currentTab = tabs[index];
    });
  }

  void _handleOnTapNavigationBarItem(int index) {
    HapticFeedback.selectionClick();
    if (tabs[index] == _currentTab) {
      popAllHistory(navigatorKeys[index]);
    }
    if (tabs[index] == TabItem.communityBoard) {
      AppEvents.postChanged.value = PostChangedEvent.refreshAll();
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
