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
}
