import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class MyLocation{
  double? latitude2;
  double? longitude2;

  Future<void> getMyCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
    Position position = await Geolocator.
      getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      latitude2 = position.latitude;
      longitude2 = position.longitude;

      debugPrint(latitude2.toString());
      debugPrint(longitude2.toString());
    } catch (e) {
      debugPrint('There was a problem with the internet connection. ');
    }
  }
}