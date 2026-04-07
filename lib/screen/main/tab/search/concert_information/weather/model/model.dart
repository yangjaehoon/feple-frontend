import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

class Model {
  Widget? getWeatherIcon(int condition) {
    if (condition < 300) {
      return SvgPicture.asset(
        'svg/weather_icon/Climacon-cloud_ligthning.svg',
        colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
      );
    } else if (condition < 600) {
      return SvgPicture.asset(
        'svg/weather_icon/climacon-cloud_snow_alt.svg',
        colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
      );
    } else if (condition == 800) {
      return SvgPicture.asset(
        'svg/weather_icon/climacon-sun.svg',
        colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
      );
    } else if (condition <= 804) {
      return SvgPicture.asset(
        'svg/weather_icon/climacon-cloud_sun.svg',
        colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
      );
    } else {
      return SvgPicture.asset(
        'svg/weather_icon/icon.svg',
        colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
      );
    }
  }

  Widget? getAirIcon(int index) {
    if (index == 1) {
      return Image.asset(
        'assets/image/air_condition/good.png',
        width: 37.0,
        height: 35.0,
      );
    } else if (index == 2) {
      return Image.asset(
        'assets/image/air_condition_icon/fair.png',
        width: 37.0,
        height: 35.0,
      );
    } else if (index == 3) {
      return Image.asset(
        'assets/image/air_condition_icon/moderate.png',
        width: 37.0,
        height: 35.0,
      );
    } else if (index == 4) {
      return Image.asset(
        'assets/image/air_condition_icon/poor.png',
        //assets/image/air_condition_icon/poor.png
        width: 37.0,
        height: 35.0,
      );
    } else if (index == 5) {
      return Image.asset(
        'assets/image/air_condition_icon/bad.png',
        //assets/image/air_condition_icon/bad.png
        width: 37.0,
        height: 35.0,
      );
    }
    return null;
  }

  Widget? getAirCondition(int index) {
    if (index == 1) {
      return Text(
        'air_very_good'.tr(),
        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      );
    } else if (index == 2) {
      return Text(
        'air_good'.tr(),
        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      );
    } else if (index == 3) {
      return Text(
        'air_moderate'.tr(),
        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      );
    } else if (index == 4) {
      return Text(
        'air_bad'.tr(),
        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      );
    } else if (index == 5) {
      return Text(
        'air_very_bad'.tr(),
        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      );
    }
    return null;
  }
}
