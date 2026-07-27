import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/weather_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_weather_bottom_sheet.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalDetailService extends Mock implements FestivalDetailService {}

String _isoDate(int daysFromNow) =>
    DateTime.now().add(Duration(days: daysFromNow)).toIso8601String().substring(0, 10);

WeatherModel _weather({
  double minTemp = 20,
  double maxTemp = 28,
  int rainProb = 30,
  String skyCode = '1',
  String ptyCode = '0',
}) {
  return WeatherModel(
    fcstDate: _isoDate(0),
    minTemp: minTemp,
    maxTemp: maxTemp,
    rainProb: rainProb,
    skyCode: skyCode,
    ptyCode: ptyCode,
  );
}

void main() {
  late MockFestivalDetailService mockService;

  setUp(() {
    mockService = MockFestivalDetailService();
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
    sl.registerSingleton<FestivalDetailService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    required String startDate,
    String endDate = '',
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        startLocale: const Locale('ko'),
        fallbackLocale: const Locale('ko'),
        path: 'assets/translations',
        useOnlyLangCode: true,
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppBottomSheet(
                    context,
                    builder: (_) => WeatherBottomSheet(
                      festivalId: 1,
                      startDate: startDate,
                      endDate: endDate,
                    ),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  group('WeatherBottomSheet 이른 조회', () {
    testWidgets('시작일이 4일 이상 남았고 아직 끝나지 않았으면 너무 이르다는 안내를 보여준다', (tester) async {
      await pump(tester, startDate: _isoDate(4));

      expect(find.text('weather_too_early'.tr()), findsOneWidget);
      verifyNever(() => mockService.fetchWeather(any()));
    });
  });

  group('WeatherBottomSheet 조회', () {
    testWidgets('3일 이내면 날씨 정보를 조회해 보여준다', (tester) async {
      when(() => mockService.fetchWeather(1))
          .thenAnswer((_) async => _weather(minTemp: 18, maxTemp: 26, rainProb: 40));

      await pump(tester, startDate: _isoDate(2));

      expect(find.text('weather_sunny'.tr()), findsOneWidget);
      expect(find.text('weather_temp_range'.tr(args: ['18', '26'])), findsOneWidget);
      expect(find.text('weather_rain_prob'.tr(args: ['40'])), findsOneWidget);
    });

    testWidgets('이미 종료된 페스티벌이면 시작일이 멀어도 바로 조회한다', (tester) async {
      when(() => mockService.fetchWeather(1)).thenAnswer((_) async => _weather());

      await pump(tester, startDate: _isoDate(-30), endDate: _isoDate(-20));

      verify(() => mockService.fetchWeather(1)).called(1);
      expect(find.text('weather_too_early'.tr()), findsNothing);
    });

    testWidgets('조회 결과가 없으면 데이터 없음 안내를 보여준다', (tester) async {
      when(() => mockService.fetchWeather(1)).thenAnswer((_) async => null);

      await pump(tester, startDate: _isoDate(1));

      expect(find.text('weather_no_data'.tr()), findsOneWidget);
    });

    testWidgets('조회 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchWeather(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return _weather(minTemp: 15, maxTemp: 22);
      });

      await pump(tester, startDate: _isoDate(1));

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('weather_temp_range'.tr(args: ['15', '22'])), findsOneWidget);
    });
  });
}
