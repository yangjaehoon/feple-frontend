import 'package:feple/common/app_events.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScreen(noticeMessage: widget.noticeMessage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppEvents.appResumed.value++;
    }
    super.didChangeAppLifecycleState(state);
  }
}
