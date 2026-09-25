import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_notice_banner.dart';
import 'package:feple/common/widget/w_offline_banner.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:feple/screen/main/tab/w_tab_navigator.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../common/app_events.dart';
import '../../model/post_changed_event.dart';
import '../../common/common.dart';
import '../../provider/user_provider.dart';

class MainScreen extends StatefulWidget {
  /// 위젯 트리 밖(홈 화면 바로가기 등 네이티브 콜백)에서 [MainScreenState]에
  /// 접근하기 위한 키. `AppState.build()`에서만 붙인다 — 위젯 트리 안에서는
  /// `context.findAncestorStateOfType<MainScreenState>()`를 대신 쓸 것.
  static final GlobalKey<MainScreenState> mainScreenKey =
      GlobalKey<MainScreenState>();

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

  /// 사용자가 탭을 직접 골랐는지. 뒤늦게 끝난 자동 로그인이 사용자가 고른
  /// 탭을 덮어쓰지 않도록 [_applyLoginTransition]이 본다.
  bool _userChoseTab = false;

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

  // 최상위 Consumer가 로그인 여부와 무관하게 같은 App 위젯을 반환하므로 이
  // State는 로그인·로그아웃을 가로질러 살아남는다. 그래서 양방향 전이를 여기서
  // 직접 처리해야 한다 — 하위 위젯의 initState는 다시 실행되지 않는다.
  void _handleAuthChanged() {
    final isLoggedIn = _userProvider?.user != null;
    final wasLoggedIn = _wasLoggedIn;
    _wasLoggedIn = isLoggedIn;
    if (!mounted || wasLoggedIn == isLoggedIn) return;
    if (isLoggedIn) {
      _applyLoginTransition();
    } else {
      _applyLogoutTransition();
    }
  }

  void _applyLogoutTransition() {
    // 각 탭의 중첩 Navigator 스택을 비운다 — 설정 등 계정 전용 화면이
    // RequireLoginGate의 로그인 유도 화면 위에 그대로 남는 것을 막는다.
    for (final key in navigatorKeys) {
      popAllHistory(key);
    }
    // 홈 탭은 게스트에게 로그인 유도 화면뿐이라, 거기 머물면 로그아웃 직후
    // 아무것도 못 보는 화면에 갇힌다. 나머지 탭은 게스트용 내용이 있으므로
    // (마이페이지도 로그인 CTA + 고객센터·약관) 보고 있던 탭을 유지한다.
    if (_currentTab != TabItem.home) return;
    _userChoseTab = false;
    _changeTab(tabs.indexOf(_landingTab));
  }

  /// 콜드스타트에선 위젯 트리가 자동 로그인보다 **먼저** 빌드된다(네이티브
  /// 스플래시는 화면을 덮을 뿐 트리를 막지 않는다). 그래서 [initState]와
  /// 앱바의 `initState`가 모두 게스트 기준으로 돌아가고, 로그인이 끝나도
  /// 엘리먼트가 재사용되어 다시 실행되지 않는다. 그 시점에 굳어버린 값을
  /// 여기서 한 번 보정한다.
  void _applyLoginTransition() {
    // 아무도 안 부르면 로그인 사용자가 알림함에 들어갔다 나오기 전까지 벨
    // 배지와 앱 아이콘 배지가 0으로 남는다.
    unawaited(sl<NotificationCountNotifier>().load());
    // 사용자가 직접 고른 탭이거나 탭 안에서 상세 화면까지 들어갔다면 보고 있던
    // 화면을 빼앗지 않는다 — 게스트용 시작 탭 그대로일 때만 옮긴다.
    // (탭 방문 이력으로는 판별할 수 없다: 검색 바로가기로 들어오면 게스트
    //  기본 탭과 같은 탭이라 이력이 늘지 않는다.)
    if (_userChoseTab) return;
    if (_currentTabNavigationKey.currentState?.canPop() ?? false) return;
    final landingTab = _landingTab;
    if (landingTab != _currentTab) _changeTab(tabs.indexOf(landingTab));
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

  /// 로고 탭 — 특정 탭이 아니라 "시작 탭으로"라는 뜻이라 [_userChoseTab]을
  /// 켜지 않는다. 게스트일 땐 시작 탭이 검색이므로, 여기서 플래그를 켜면
  /// 로그인 직후 정작 요청한 홈으로 못 가고 검색에 남는다.
  void goHome() {
    final homeIndex = tabs.indexOf(_landingTab);
    popAllHistory(navigatorKeys[homeIndex]);
    _changeTab(homeIndex);
  }

  /// 홈 화면 바로가기(Quick Actions) 등 위젯 트리 밖에서 특정 탭으로 전환한다.
  void switchToTab(TabItem tab) {
    final index = tabs.indexOf(tab);
    popAllHistory(navigatorKeys[index]);
    _userChoseTab = true;
    _changeTab(index);
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
    _userChoseTab = true;
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
