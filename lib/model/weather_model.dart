enum SkyCode {
  sunny('SUNNY'),
  cloudy('CLOUDY'),
  overcast('OVERCAST');

  const SkyCode(this.value);
  final String value;

  static SkyCode fromValue(String? value) => SkyCode.values.firstWhere(
        (s) => s.value == value,
        orElse: () => SkyCode.sunny,
      );
}

enum PtyCode {
  none('NONE'),
  rain('RAIN'),
  rainSnow('RAIN_SNOW'),
  snow('SNOW'),
  shower('SHOWER');

  const PtyCode(this.value);
  final String value;

  static PtyCode fromValue(String? value) => PtyCode.values.firstWhere(
        (s) => s.value == value,
        orElse: () => PtyCode.none,
      );
}

class WeatherModel {
  final String fcstDate;
  final double minTemp;
  final double maxTemp;
  final int rainProb;
  final SkyCode skyCode;
  final PtyCode ptyCode;

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
      skyCode: SkyCode.fromValue(json['skyCode'] as String?),
      ptyCode: PtyCode.fromValue(json['ptyCode'] as String?),
    );
  }

  // 강수 형태가 있으면 우선, 없으면 하늘 상태로 아이콘 결정
  String get conditionKey {
    return switch (ptyCode) {
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
}
