import 'package:fast_app_base/screen/main/tab/home/concert_information/weather/screens/weather_screen.dart';
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
  double? latitude3;
  double? longitude3;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLocation();
  }

  void getLocation() async {
    MyLocation myLocation = MyLocation();
    await myLocation.getMyCurrentLocation();
    latitude3 = myLocation.latitude2;
    longitude3 = myLocation.longitude2;
    print(latitude3);
    print(longitude3);

    Network network = Network(
        'https://api.openweathermap.org/data/2.5/weather'
            '?lat=${latitude3}&lon=${longitude3}&appid=${apiKey}&units=metric',
        'http://api.openweathermap.org/data/2.5/air_pollution'
            '?lat=${latitude3}&lon=${longitude3}&appid=${apiKey}');
    //Network network = Network('https://samples.openweathermap.org/data/2.5/weather?q=London&appid=b1b15e88fa797225412429c1c50c122a1');
    var weatherData = await network.getJsonData();
    print(weatherData);

    var airData = await network.getAirData();
    print(airData);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WeatherScreen(
        parseWeatherData: weatherData,
        parseAirPollution: airData,
      );
    }));
  }

/*
  void fetchData() async{

      var myJson = parsingData['weather'][0]['description'];
      var wind = parsingData(jsonData)['wind']['speed'];
      var id = parsingData['id'];
      print(myJson);
      print(wind);
      print(id);
    }
    else{
      print('response.statusCode');
    }

  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      body: Center(
        child: SpinKitDoubleBounce(
          color: Colors.white,
          size: 80.0,
        ),
      ),
    );
  }
}
