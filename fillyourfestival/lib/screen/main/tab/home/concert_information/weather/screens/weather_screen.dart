import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:intl/intl.dart';
import '../model/model.dart';

class WeatherScreen extends StatefulWidget {
  WeatherScreen({this.parseWeatherData, this.parseAirPollution});
  final dynamic parseWeatherData;
  final dynamic parseAirPollution;

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Model model = Model();
  String? cityName;
  int temp = 0;
  Widget? icon;
  String? des;
  Widget? airIcon;
  Widget? airState;
  double? dust1;
  double? dust2;
  var date = DateTime.now();

  @override
  void initState() {
    super.initState();
    updateData(widget.parseWeatherData, widget.parseAirPollution);
  }

  void updateData(dynamic weatherData, dynamic airData) {
    double temp2 = weatherData['main']['temp'];
    int condition = weatherData['weather'][0]['id'];
    int index = airData['list'][0]['main']['aqi'];
    des = weatherData['weather'][0]['description'];
    dust1 = airData['list'][0]['components']['pm10'];
    dust2 = airData['list'][0]['components']['pm2_5'];
    temp = temp2.round();
    cityName = weatherData['name'];
    icon = model.getWeatherIcon(condition);
    airIcon = model.getAirIcon(index);
    airState = model.getAirCondition(index);
  }

  String? getSystemTime() {
    var now = DateTime.now();
    return DateFormat("h:mm a").format(now);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          leading: IconButton(
            icon: const Icon(Icons.near_me_rounded, color: Colors.white),
            onPressed: () {},
            iconSize: 28.0,
          ),
          actions: [
            IconButton(
              onPressed: () {},
              iconSize: 28.0,
              icon: const Icon(
                Icons.location_searching_rounded,
                color: Colors.white,
              ),
            )
          ],
        ),
        body: Container(
          color: colors.appBarColor,
          child: Stack(
            children: [
              Container(),
              Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 150.0),
                                  Text(
                                    '$cityName',
                                    style: GoogleFonts.lato(
                                      fontSize: 35.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      TimerBuilder.periodic(
                                        (const Duration(minutes: 1)),
                                        builder: (context) {
                                          return Text(
                                            '${getSystemTime()}',
                                            style: GoogleFonts.lato(
                                                fontSize: 16.0,
                                                color: Colors.white),
                                          );
                                        },
                                      ),
                                      Text(DateFormat('EEEE, ').format(date),
                                          style: GoogleFonts.lato(
                                              fontSize: 16.0,
                                              color: Colors.white)),
                                      Text(
                                          DateFormat('d MMM, yyy').format(date),
                                          style: GoogleFonts.lato(
                                              fontSize: 16.0,
                                              color: Colors.white))
                                    ],
                                  )
                                ]),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$temp\u2103',
                                  style: GoogleFonts.lato(
                                    fontSize: 85.0,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    icon!,
                                    const SizedBox(width: 10.0),
                                    Text('$des',
                                        style: GoogleFonts.lato(
                                          fontSize: 16.0,
                                          color: Colors.white,
                                        ))
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const Divider(
                            height: 15.0,
                            thickness: 2.0,
                            color: Colors.white30,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'AQI(대기질지수)',
                                    style: GoogleFonts.lato(
                                      fontSize: 14.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  airIcon!,
                                  const SizedBox(height: 10.0),
                                  airState!,
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '미세먼지',
                                    style: GoogleFonts.lato(
                                      fontSize: 14.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    '$dust1',
                                    style: GoogleFonts.lato(
                                      fontSize: 24.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    '㎍/m³',
                                    style: GoogleFonts.lato(
                                        fontSize: 14.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '초미세먼지',
                                    style: GoogleFonts.lato(
                                      fontSize: 14.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    '$dust2',
                                    style: GoogleFonts.lato(
                                      fontSize: 24.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    '㎍/m³',
                                    style: GoogleFonts.lato(
                                        fontSize: 14.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ))
            ],
          ),
        ));
  }
}
