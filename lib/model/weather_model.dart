class WeatherModel {
  final String fcstDate;
  final double minTemp;
  final double maxTemp;
  final int rainProb;
  final String skyCode;   // 1=맑음 3=구름많음 4=흐림
  final String ptyCode;   // 0=없음 1=비 2=비/눈 3=눈 4=소나기

  const WeatherModel({
    required this.fcstDate,
    required this.minTemp,
    required this.maxTemp,
    required this.rainProb,
    required this.skyCode,
    required this.ptyCode,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      fcstDate: json['fcstDate'] as String? ?? '',
      minTemp: (json['minTemp'] as num?)?.toDouble() ?? 0,
      maxTemp: (json['maxTemp'] as num?)?.toDouble() ?? 0,
      rainProb: (json['rainProb'] as num?)?.toInt() ?? 0,
      skyCode: json['skyCode'] as String? ?? '1',
      ptyCode: json['ptyCode'] as String? ?? '0',
    );
  }

  // 강수 형태가 있으면 우선, 없으면 하늘 상태로 아이콘 결정
  String get conditionKey {
    return switch (ptyCode) {
      '1' => 'weather_rain',
      '2' => 'weather_snow_rain',
      '3' => 'weather_snow',
      '4' => 'weather_shower',
      _ => switch (skyCode) {
        '3' => 'weather_cloudy',
        '4' => 'weather_overcast',
        _ => 'weather_sunny',
      },
    };
  }

}
