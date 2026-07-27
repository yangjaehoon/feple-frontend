import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/booth_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_booth_map.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalDetailService extends Mock implements FestivalDetailService {}

BoothModel _booth({
  int id = 1,
  String name = '부스',
  String boothType = 'FOOD',
  String boothTypeName = '푸드',
}) =>
    BoothModel(
      id: id,
      name: name,
      boothType: boothType,
      boothTypeName: boothTypeName,
      latitude: 37.5665,
      longitude: 126.9780,
      // imageUrl을 지정하면 BoothMarkerFactory가 실제 네트워크 요청을 시도하므로
      // 테스트에서는 항상 null로 두어 기본 마커(defaultMarkerWithHue)를 쓰게 한다
      imageUrl: null,
    );

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

  Future<void> pump(WidgetTester tester) async {
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
              body: SingleChildScrollView(
                child: FestivalBoothMap(festivalId: 1, festivalLat: 37.5, festivalLng: 127.0),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FestivalBoothMap 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      when(() => mockService.fetchBooths(1)).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 50), () => []),
      );

      await pump(tester);

      expect(find.byType(GoogleMap), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('FestivalBoothMap 에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchBooths(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [];
      });

      await pump(tester);
      await tester.pump();

      expect(find.text('load_error'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('no_booth'.tr()), findsOneWidget);
    });
  });

  group('FestivalBoothMap 빈 목록', () {
    testWidgets('부스가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchBooths(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_booth'.tr()), findsOneWidget);
    });
  });

  group('FestivalBoothMap 지도', () {
    testWidgets('부스가 있으면 지도와 범례를 보여준다', (tester) async {
      when(() => mockService.fetchBooths(1))
          .thenAnswer((_) async => [_booth(name: '떡볶이 부스')]);

      await pump(tester);
      await tester.pump();
      await tester.pump();

      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('booth_food'.tr()), findsOneWidget);
      expect(find.text('booth_alcohol'.tr()), findsOneWidget);
      expect(find.text('booth_event'.tr()), findsOneWidget);
    });
  });

  group('FestivalBoothMap 새로고침', () {
    testWidgets('refresh() 호출 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchBooths(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      final key = GlobalKey<FestivalBoothMapState>();
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
                body: SingleChildScrollView(
                  child: FestivalBoothMap(key: key, festivalId: 1),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(callCount, 1);

      key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
