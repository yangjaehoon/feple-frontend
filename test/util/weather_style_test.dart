import 'package:feple/common/constant/app_colors.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/weather_style.dart';
import 'package:flutter_test/flutter_test.dart';

WeatherModel _weather({SkyCode skyCode = SkyCode.sunny, PtyCode ptyCode = PtyCode.none}) {
  return WeatherModel(
    fcstDate: '20260801',
    minTemp: 20,
    maxTemp: 28,
    rainProb: 10,
    skyCode: skyCode,
    ptyCode: ptyCode,
  );
}

void main() {
  group('rainProbColor', () {
    test('70% 이상이면 high 색상', () {
      expect(rainProbColor(70), AppColors.rainProbHigh);
      expect(rainProbColor(100), AppColors.rainProbHigh);
    });

    test('40~69%면 medium 색상', () {
      expect(rainProbColor(40), AppColors.rainProbMedium);
      expect(rainProbColor(69), AppColors.rainProbMedium);
    });

    test('40% 미만이면 low 색상', () {
      expect(rainProbColor(0), AppColors.rainProbLow);
      expect(rainProbColor(39), AppColors.rainProbLow);
    });
  });

  group('WeatherConditionIcon.conditionIcon', () {
    test('ptyCode가 강수 형태면 그것으로 결정된다 (skyCode 무시)', () {
      expect(_weather(ptyCode: PtyCode.rain, skyCode: SkyCode.sunny).conditionIcon, '🌧');
      expect(_weather(ptyCode: PtyCode.rainSnow, skyCode: SkyCode.sunny).conditionIcon, '🌨');
      expect(_weather(ptyCode: PtyCode.snow, skyCode: SkyCode.sunny).conditionIcon, '❄️');
      expect(_weather(ptyCode: PtyCode.shower, skyCode: SkyCode.sunny).conditionIcon, '🌦');
    });

    test('ptyCode가 없으면(none) skyCode로 결정된다', () {
      expect(_weather(ptyCode: PtyCode.none, skyCode: SkyCode.cloudy).conditionIcon, '🌤');
      expect(_weather(ptyCode: PtyCode.none, skyCode: SkyCode.overcast).conditionIcon, '☁️');
      expect(_weather(ptyCode: PtyCode.none, skyCode: SkyCode.sunny).conditionIcon, '☀️');
    });
  });
}
