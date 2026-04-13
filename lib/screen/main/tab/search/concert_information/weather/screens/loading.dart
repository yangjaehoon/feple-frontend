import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/weather/screens/weather_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../data/my_location.dart';
import '../data/network.dart';


const apiKey = '8a5641156b4c3c4db251c584d89e78e1';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  void getLocation() async {
    MyLocation myLocation = MyLocation();
    await myLocation.getMyCurrentLocation();
    latitude = myLocation.latitude;
    longitude = myLocation.longitude;

    Network network = Network(
        'https://api.openweathermap.org/data/2.5/weather'
            '?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
        'http://api.openweathermap.org/data/2.5/air_pollution'
            '?lat=$latitude&lon=$longitude&appid=$apiKey');
    var weatherData = await network.getJsonData();
    var airData = await network.getAirData();

    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WeatherScreen(
        parseWeatherData: weatherData,
        parseAirPollution: airData,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.appBarColor,
      body: Center(
        child: SpinKitDoubleBounce(
          color: Colors.white,
          size: 80.0,
        ),
      ),
    );
  }
}
