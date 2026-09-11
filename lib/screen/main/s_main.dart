import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_notice_banner.dart';
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
  /// 앱 상단 공지 배너 문구 (`AppConfigModel.noticeMessage`). null이면 미노출.
  final String? noticeMessage;

  const MainScreen({super.key, this.noticeMessage});

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

  UserProvider? _userProvider;
  bool _wasLoggedIn = false;

  int get _currentIndex => tabs.indexOf(_currentTab);

  // 게스트에게 홈 탭은 로그인 유도 화면이라 로고 탭·뒤로가기 복귀 지점으로
  // 부적절함 — 비계정 탭 중에서도 스와이퍼+아티스트 발견 등 탐색 콘텐츠가 있는
  // 검색 탭으로 대신 보낸다(단순 목록뿐인 페스티벌 목록 탭보다 첫인상이 풍부).
  // 로그인 상태는 탭 전환 시점마다 새로 확인해, 게스트로 시작했다가 화면 안에서
  // 로그인해도(게이트나 상단바 로그인 버튼 경유) 곧바로 홈으로 정확히 돌아간다.
  TabItem get _landingTab =>
      Provider.of<UserProvider>(context, listen: false).user == null
          ? TabItem.search
          : TabItem.home;

  GlobalKey<NavigatorState> get _currentTabNavigationKey =>
      navigatorKeys[_currentIndex];

  static const bool extendBody = true;

  static const double bottomNavigationBarBorderRadius = 30.0;

  @override
  void initState() {
    super.initState();
    // 게스트는 계정 기반 탭인 홈(팔로우 아티스트/좋아요 페스티벌)이 로그인 유도
    // 화면으로 막혀 있으므로, 탐색 콘텐츠가 있는 검색 탭으로 시작한다.
    _currentTab = _landingTab;
    _visitedTabs.add(_currentIndex);
    _tabObservers = List.generate(
      tabs.length,
      (_) => _NavBarObserver(() {
        if (mounted) _showBottomNav.value = true;
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<UserProvider>();
    if (identical(provider, _userProvider)) return;
    _userProvider?.removeListener(_handleAuthChanged);
    _userProvider = provider;
    _wasLoggedIn = provider.user != null;
    provider.addListener(_handleAuthChanged);
  }

  // 로그아웃·세션 만료로 로그인 상태가 풀리면 각 탭의 중첩 Navigator 스택을
  // 비운다. 로그인 여부와 무관하게 최상위 Consumer가 같은 App 위젯을 반환해
  // 이 스택이 살아남으므로, 설정 등 계정 전용 화면이 RequireLoginGate의
  // 로그인 유도 화면 위에 그대로 남는 것을 막는다.
  void _handleAuthChanged() {
    final isLoggedIn = _userProvider?.user != null;
    final loggedOut = _wasLoggedIn && !isLoggedIn;
    _wasLoggedIn = isLoggedIn;
    if (!loggedOut || !mounted) return;
    for (final key in navigatorKeys) {
      popAllHistory(key);
    }
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
    _userProvider?.removeListener(_handleAuthChanged);
    _showBottomNav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Subscribe to locale changes so bottom nav labels re-translate immediately
    return NoticeBanner(
      message: widget.noticeMessage,
      child: OfflineBanner(
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
    final bottomInset = _resolveBottomNavInset(context);
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

  // 폰 폭에서는 시스템 하단 inset을 (8~20)으로 clamp한다(AppDimens.bottomNavMaxInset
  // 주석 참고). 그런데 태블릿급 폭(펼친 폴더블 등)에서는 Android가 대화면 태스크바를
  // 띄우고 이를 60dp 안팎의 navigationBars inset으로 보고하는데, 그대로 20으로
  // 깎으면 탭바 라벨이 실제로 태스크바에 가려진다. 태블릿급 폭에서만 상한을
  // 시스템 inset 그대로 따르도록 완화해 이 겹침을 막는다.
  //
  // Flutter에는 "이 inset이 태스크바 때문인지"를 구분하는 API가 없어 화면 폭을
  // 대리 신호로 쓴다 — 그 결과 3버튼 내비게이션을 쓰는 일반 태블릿(inset
  // ~48dp)도 20 대신 48을 그대로 쓰게 돼 탭바 아래 여백이 좀 더 넓어질 수 있다.
  // 앱이 세로 고정(android:screenOrientation="portrait" + portraitUp)이라 폰이
  // 가로로 눕는 경우는 없지만, 데스크톱 모드/자유형 창처럼 폭만 넓은 멀티윈도우
  // 상태에서도 같은 트레이드오프가 적용된다. 의도된 선택: 여백이 넓어지는 건
  // 미관상 아쉬운 정도지만, 태스크바가 실제로 탭을 가려 못 누르게 되는 건
  // 기능 결함이라 후자를 우선한다.
  double _resolveBottomNavInset(BuildContext context) {
    final systemBottomInset = MediaQuery.paddingOf(context).bottom;
    final isTabletWidth =
        MediaQuery.sizeOf(context).width >= AppDimens.tabletBreakpointWidth;
    final maxInset = isTabletWidth
        ? math.max(AppDimens.bottomNavMaxInset, systemBottomInset)
        : AppDimens.bottomNavMaxInset;
    return systemBottomInset.clamp(AppDimens.bottomNavMinInset, maxInset).toDouble();
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
