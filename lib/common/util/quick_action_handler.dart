import 'package:feple/common/common.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

/// 홈 화면 아이콘을 길게 눌러 나오는 바로가기(Android App Shortcuts / iOS
/// Quick Actions). 로그인 여부와 무관하게 항상 등록해두고, 실제 화면 접근
/// 제한은 각 탭이 이미 갖고 있는 게스트 게이트가 처리한다([TabItem] 참고).
class QuickActionHandler {
  static const _typeSearch = 'search';
  static const _typeCommunity = 'community';

  // Flutter 에셋이 아니라 **네이티브 리소스** 이름이다 — 양쪽에 같은 이름으로
  // 넣어둬야 한다(Android: res/drawable-*dpi/, iOS: Assets.xcassets/).
  // 빠뜨리면 예외 없이 아이콘 자리가 빈 원으로만 보인다.
  // 각 탭 아이콘(Icons.search_rounded / Icons.forum_rounded)과 같은 글리프.
  static const _iconSearch = 'ic_shortcut_search';
  static const _iconCommunity = 'ic_shortcut_community';

  final _quickActions = const QuickActions();

  /// 앱 시작 시, 그리고 언어 변경 시 다시 호출해 바로가기 라벨을 최신 언어로
  /// 갱신한다.
  Future<void> register() async {
    unawaited(_quickActions.initialize(_handleAction));
    try {
      await _quickActions.setShortcutItems([
        ShortcutItem(
          type: _typeSearch,
          localizedTitle: 'quick_action_search'.tr(),
          icon: _iconSearch,
        ),
        ShortcutItem(
          type: _typeCommunity,
          localizedTitle: 'quick_action_community'.tr(),
          icon: _iconCommunity,
        ),
      ]);
    } catch (e) {
      debugPrint('[QuickAction] 바로가기 등록 실패: $e');
    }
  }

  void _handleAction(String type) {
    // MainScreen(App 위젯)은 로그인·온보딩 완료 후에만 존재 — 그 전에 바로가기를
    // 탭하면 currentState가 null이라 조용히 무시된다(딥링크와 달리 로그인/온보딩
    // 중간에 탭 전환을 끼워 넣을 자연스러운 지점이 없음).
    final mainState = MainScreen.mainScreenKey.currentState;
    if (mainState == null) return;
    switch (type) {
      case _typeSearch:
        mainState.switchToTab(TabItem.search);
      case _typeCommunity:
        mainState.switchToTab(TabItem.communityBoard);
    }
  }
}
