import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../../../../auth/keys.dart';

class FtvMapWidget extends StatefulWidget {
  const FtvMapWidget({Key? key}) : super(key: key);

  @override
  _FtvMapWidgetState createState() => _FtvMapWidgetState();
}

class _FtvMapWidgetState extends State<FtvMapWidget> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: const NaverMapViewOptions(
        indoorEnable: true,
        locationButtonEnable: false,
        consumeSymbolTapEvents: false,
      ),
      onMapReady: (controller) async {
        _mapControllerCompleter.complete(controller);
        log("onMapReady", name: "onMapReady");
      },
    );
  }
}
