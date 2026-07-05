import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_text_scale_clamp.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  static bool isForeground = true;
  /// 앱이 포그라운드로 복귀할 때마다 값이 증가 — 구독 측에서 refresh 트리거용
  static final resumeEvent = ValueNotifier<int>(0);

  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> with Nav, WidgetsBindingObserver {
  @override
  GlobalKey<NavigatorState> get navigatorKey => App.navigatorKey;

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: App.navigatorKey,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Feple',
      theme: context.themeType.themeData,
      builder: clampTextScaleBuilder,
      home: const MainScreen(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        App.isForeground = true;
        App.resumeEvent.value++;
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        App.isForeground = false;
        break;
      case AppLifecycleState.detached:
        break;
      default:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }
}
