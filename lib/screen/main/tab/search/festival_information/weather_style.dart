import 'package:feple/common/constant/app_colors.dart';
import 'package:feple/model/weather_model.dart';
import 'package:flutter/material.dart';

Color rainProbColor(int prob) {
  if (prob >= 70) return AppColors.rainProbHigh;
  if (prob >= 40) return AppColors.rainProbMedium;
  return AppColors.rainProbLow;
}

extension WeatherConditionIcon on WeatherModel {
  String get conditionIcon => switch (ptyCode) {
        PtyCode.rain => '🌧',
        PtyCode.rainSnow => '🌨',
        PtyCode.snow => '❄️',
        PtyCode.shower => '🌦',
        PtyCode.none => switch (skyCode) {
          SkyCode.cloudy => '🌤',
          SkyCode.overcast => '☁️',
          SkyCode.sunny => '☀️',
        },
      };

  // 강수 형태가 있으면 우선, 없으면 하늘 상태로 아이콘 결정
  String get conditionKey => switch (ptyCode) {
        PtyCode.rain => 'weather_rain',
        PtyCode.rainSnow => 'weather_snow_rain',
        PtyCode.snow => 'weather_snow',
        PtyCode.shower => 'weather_shower',
        PtyCode.none => switch (skyCode) {
          SkyCode.cloudy => 'weather_cloudy',
          SkyCode.overcast => 'weather_overcast',
          SkyCode.sunny => 'weather_sunny',
        },
      };
}
