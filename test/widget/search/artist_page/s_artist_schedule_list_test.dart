import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_schedule_list.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistScheduleService extends Mock implements ArtistScheduleService {}
class MockFestivalService extends Mock implements FestivalService {}

ArtistScheduleModel _schedule({
  int festivalId = 1,
  String title = '일정',
  String? startDate,
}) =>
    ArtistScheduleModel(
      festivalId: festivalId,
      title: title,
      startDate: startDate,
      eventType: EventType.festival,
      coArtists: const [],
    );

void main() {
  late MockArtistScheduleService mockScheduleService;
  late MockFestivalService mockFestivalService;

  setUp(() {
    mockScheduleService = MockArtistScheduleService();
    mockFestivalService = MockFestivalService();
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    sl.registerSingleton<ArtistScheduleService>(mockScheduleService);
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
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
            home: ArtistScheduleListScreen(artistId: 1, artistName: '아티스트'),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ArtistScheduleListScreen 렌더링', () {
    testWidgets('다가오는 일정과 지난 일정을 구분해서 보여준다', (tester) async {
      final future = DateTime.now().add(const Duration(days: 10));
      final past = DateTime.now().subtract(const Duration(days: 10));
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async => [
            _schedule(festivalId: 1, title: '다가올 일정', startDate: future.toIso8601String()),
            _schedule(festivalId: 2, title: '지난 일정', startDate: past.toIso8601String()),
          ]);

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('schedule_upcoming'.tr()), findsOneWidget);
      expect(find.text('schedule_past'.tr()), findsOneWidget);
      expect(find.text('다가올 일정'), findsOneWidget);
      expect(find.text('지난 일정'), findsOneWidget);
    });

    testWidgets('일정이 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_schedule'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태를 보여준다', (tester) async {
      when(() => mockScheduleService.fetchSchedule(1))
          .thenAnswer((_) async => throw Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('ArtistScheduleListScreen 새로고침', () {
    testWidgets('pull-to-refresh 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockScheduleService.fetchSchedule(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      await pump(tester);
      await tester.pump();
      expect(callCount, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });

  // 일정 탭 시 fetchById 후 이동하는 FestivalInformationFragment는 FestivalPoster/
  // FestivalArtists/BoardPreviewSection/FestivalTimetable/FestivalSetlist/
  // FestivalBoothMap 등 다수의 sl<> 의존성이 필요한 무거운 화면이라 다른 위젯의
  // 네비게이션 테스트에서는 깊이 들어가지 않는다(기존 컨벤션) — fetchById가
  // pending 상태(미완료 Future)일 때까지만 확인해 실제 push가 일어나지 않게 한다
  group('ArtistScheduleListScreen 일정 탭', () {
    testWidgets('일정을 탭하면 페스티벌 정보를 조회한다', (tester) async {
      when(() => mockScheduleService.fetchSchedule(1))
          .thenAnswer((_) async => [_schedule(festivalId: 5, title: '일정')]);
      when(() => mockFestivalService.fetchById(5))
          .thenAnswer((_) => Completer<FestivalModel>().future);

      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('일정'));
      await tester.pump();

      verify(() => mockFestivalService.fetchById(5)).called(1);
    });
  });
}
