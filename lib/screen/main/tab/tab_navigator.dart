import 'package:feple/injection.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/screen/main/tab/tab_item.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final navigator = Navigator(
      key: navigatorKey,
      observers: observers,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => tabItem.firstPage,
        );
      },
    );

    // FestivalPreviewProvider는 검색탭·축제탭 둘 다 사용
    if (tabItem == TabItem.concertList || tabItem == TabItem.search) {
      return ChangeNotifierProvider(
        create: (_) => FestivalPreviewProvider(sl<FestivalService>()),
        child: navigator,
      );
    }

    return navigator;
  }
}
