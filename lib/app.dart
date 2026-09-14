import 'dart:async';

import 'package:feple/common/app_events.dart';
import 'package:feple/common/util/quick_action_handler.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  /// 앱 상단 공지 배너 문구 (`AppConfigModel.noticeMessage`). null이면 미노출.
  final String? noticeMessage;

  const App({super.key, this.noticeMessage});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // App은 Localizations 하위(게스트 포함, 로그인 상태와 무관하게 생성됨)라
    // 여기서 register()를 부르면 '.tr()'이 항상 로딩 완료된 번역을 쓴다.
    // MyApp.initState()에서 바로 부르면 EasyLocalization 번역 로딩이 아직 안
    // 끝나 원본 키가 그대로 나가는 문제가 실측으로 확인됨.
    unawaited(sl<QuickActionHandler>().register());
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppEvents.appResumed.value++;
    }
    super.didChangeAppLifecycleState(state);
  }
}
