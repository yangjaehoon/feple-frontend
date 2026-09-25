import 'dart:async';

import 'package:feple/common/app_events.dart';
import 'package:feple/common/util/quick_action_handler.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:flutter/material.dart';

/// 로그인·게스트 공통의 앱 루트. 앱 전역 부트스트랩(생명주기 관찰, 홈 화면
/// 바로가기 등록)을 맡고 화면 자체는 [MainScreen]에 맡긴다.
///
/// **주의**: 이 위젯은 `main.dart`의 `Consumer<UserProvider>` 아래에 있는데,
/// 그쪽 루트 라우팅(`_rootDestination`)이 게스트와 로그인 사용자에게
/// **모두 같은 `App`**을 반환한다.
/// 그래서 게이트 화면을 거치지 않는 전이(콜드스타트 자동 로그인, 앱 안에서의
/// 로그인·로그아웃)에서는 엘리먼트가 재사용되어 하위 State의 `initState`가
/// **다시 실행되지 않는다**. 로그인 여부에 따라 달라져야 하는 값은 하위
/// `initState`가 아니라 전이를 감지하는 쪽(`MainScreenState._handleAuthChanged`)
/// 에서 보정할 것 — 콜드스타트에서 트리가 자동 로그인보다 먼저 빌드되는 탓에
/// 게스트 기준 값이 그대로 굳는 사고가 있었다.
///
/// 반대로 `_rootDestination`이 `App`보다 먼저 고르는 화면(점검·강제 업데이트·
/// 나이확인·온보딩)을 거치면 위젯 타입이 달라져 `App` 엘리먼트가 폐기되고,
/// 복귀 시 `initState`가 다시 돈다. "앱 실행당 한 번"이 보장돼야 하는 작업을
/// 여기 두지 말 것.
class App extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  /// 앱 상단 공지 배너 문구 (`AppConfigModel.noticeMessage`). null이면 미노출.
  final String? noticeMessage;

  const App({super.key, this.noticeMessage});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // register()는 '.tr()'을 쓰는데, '.tr()'은 위젯 트리가 아니라 전역
    // Localization.instance를 읽는다 — 즉 트리 위치가 아니라 **빌드 시점**이
    // 관건이다. App은 MaterialApp의 home이라 localizationsDelegates가 번역
    // 로딩을 끝낸 뒤에야 빌드되므로 여기서는 안전하다.
    // MyApp.initState()는 EasyLocalization 하위인데도 즉시 실행돼(로딩 완료를
    // 기다리지 않음) 원본 키가 그대로 나가는 것을 실측으로 확인했다.
    unawaited(sl<QuickActionHandler>().register());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      AppEvents.appResumed.value++;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScreen(key: MainScreen.mainScreenKey, noticeMessage: widget.noticeMessage);
  }
}
