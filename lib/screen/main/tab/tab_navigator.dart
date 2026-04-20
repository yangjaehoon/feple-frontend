import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:flutter/material.dart';

class TabNavigator extends StatelessWidget {
  const TabNavigator({
    super.key,
    required this.tabItem,
    required this.navigatorKey,
    this.observers = const [],
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final TabItem tabItem;
  final List<NavigatorObserver> observers;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: observers,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => tabItem.firstPage,
        );
      },
    );
  }
}
