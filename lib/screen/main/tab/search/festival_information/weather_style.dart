import 'package:feple/model/weather_model.dart';
import 'package:flutter/material.dart';

Color rainProbColor(int prob) {
  if (prob >= 70) return const Color(0xFF1565C0);
  if (prob >= 40) return const Color(0xFF42A5F5);
  return const Color(0xFF90CAF9);
}

extension WeatherConditionIcon on WeatherModel {
  String get conditionIcon => switch (ptyCode) {
        '1' => '🌧',
        '2' => '🌨',
        '3' => '❄️',
        '4' => '🌦',
        _ => switch (skyCode) {
          '3' => '🌤',
          '4' => '☁️',
          _ => '☀️',
        },
      };
}
