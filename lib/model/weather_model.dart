import 'json_reader.dart';

enum SkyCode {
  sunny('SUNNY'),
  cloudy('CLOUDY'),
  overcast('OVERCAST');

  const SkyCode(this.value);
  final String value;

  /// 매칭되는 값이 없으면 null. 호출부가 폴백을 정한다.
  static SkyCode? fromValue(String? value) {
    for (final code in SkyCode.values) {
      if (code.value == value) return code;
    }
    return null;
  }
}

enum PtyCode {
  none('NONE'),
  rain('RAIN'),
  rainSnow('RAIN_SNOW'),
  snow('SNOW'),
  shower('SHOWER');

  const PtyCode(this.value);
  final String value;

  /// 매칭되는 값이 없으면 null. 호출부가 폴백을 정한다.
  static PtyCode? fromValue(String? value) {
    for (final code in PtyCode.values) {
      if (code.value == value) return code;
    }
    return null;
  }
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
      fcstDate: json.str('fcstDate'),
      minTemp: json.dbl('minTemp'),
      maxTemp: json.dbl('maxTemp'),
      rainProb: json.integer('rainProb'),
      skyCode: SkyCode.fromValue(json.strOrNull('skyCode')) ?? SkyCode.sunny,
      ptyCode: PtyCode.fromValue(json.strOrNull('ptyCode')) ?? PtyCode.none,
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
