class AirQualityModel {
  final String stationName;
  final String sidoName;
  final String pm10Value;
  final String pm25Value;
  final String pm10Grade;
  final String pm25Grade;
  final String khaiValue;
  final String khaiGrade;
  final String dataTime;

  const AirQualityModel({
    required this.stationName,
    required this.sidoName,
    required this.pm10Value,
    required this.pm25Value,
    required this.pm10Grade,
    required this.pm25Grade,
    required this.khaiValue,
    required this.khaiGrade,
    required this.dataTime,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    return AirQualityModel(
      stationName: json['stationName'] as String? ?? '-',
      sidoName: json['sidoName'] as String? ?? '-',
      pm10Value: json['pm10Value'] as String? ?? '-',
      pm25Value: json['pm25Value'] as String? ?? '-',
      pm10Grade: json['pm10Grade'] as String? ?? '-',
      pm25Grade: json['pm25Grade'] as String? ?? '-',
      khaiValue: json['khaiValue'] as String? ?? '-',
      khaiGrade: json['khaiGrade'] as String? ?? '-',
      dataTime: json['dataTime'] as String? ?? '-',
    );
  }

  // 1=좋음, 2=보통, 3=나쁨, 4=매우나쁨
  static String gradeKey(String grade) {
    return switch (grade) {
      '1' => 'air_very_good',
      '2' => 'air_good',
      '3' => 'air_bad',
      '4' => 'air_very_bad',
      _ => 'air_moderate',
    };
  }
}
