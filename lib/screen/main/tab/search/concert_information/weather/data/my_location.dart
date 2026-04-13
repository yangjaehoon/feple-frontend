import 'package:geolocator/geolocator.dart';

class MyLocation{
  double? latitude;
  double? longitude;

  Future<void> getMyCurrentLocation() async {
    try {
      await Geolocator.requestPermission();
    Position position = await Geolocator.
      getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (_) {}
  }
}
