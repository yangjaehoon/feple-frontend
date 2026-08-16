import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_schedule_list.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_schedule.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_schedule_list_tile.dart';
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
  late MockArtistScheduleService mockService;

  setUp(() {
    mockService = MockArtistScheduleService();
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    sl.registerSingleton<ArtistScheduleService>(mockService);
    // ArtistScheduleListScreen(헤더 탭 시 이동하는 화면)의 필드 초기화에서
    // sl<FestivalService>()를 즉시 호출하므로 함께 등록해야 한다.
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(MockFestivalService());
  });

  tearDown(() {
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
  });

  Future<void> pump(WidgetTester tester, {GlobalKey<ArtistScheduleState>? key}) async {
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
              body: ArtistSchedule(key: key, artistId: 1, artistName: '아티스트'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ArtistSchedule 렌더링', () {
    testWidgets('다가오는 일정만 보여준다', (tester) async {
      final future = DateTime.now().add(const Duration(days: 10));
      final past = DateTime.now().subtract(const Duration(days: 10));
      when(() => mockService.fetchSchedule(1)).thenAnswer((_) async => [
            _schedule(festivalId: 1, title: '다가올 일정', startDate: future.toIso8601String()),
            _schedule(festivalId: 2, title: '지난 일정', startDate: past.toIso8601String()),
          ]);

      await pump(tester);
      await tester.pump();

      expect(find.text('다가올 일정'), findsOneWidget);
      expect(find.text('지난 일정'), findsNothing);
    });

    testWidgets('다가오는 일정이 3개보다 많으면 상위 3개만 보여준다', (tester) async {
      final future = DateTime.now().add(const Duration(days: 10));
      when(() => mockService.fetchSchedule(1)).thenAnswer((_) async => [
            for (var i = 1; i <= 4; i++)
              _schedule(
                festivalId: i,
                title: '일정$i',
                startDate: future.add(Duration(days: i)).toIso8601String(),
              ),
          ]);

      await pump(tester);
      await tester.pump();

      expect(find.byType(ScheduleListTile), findsNWidgets(3));
      expect(find.text('일정1'), findsOneWidget);
      expect(find.text('일정4'), findsNothing);
    });

    testWidgets('다가오는 일정이 없으면 안내 문구를 보여준다', (tester) async {
      final past = DateTime.now().subtract(const Duration(days: 10));
      when(() => mockService.fetchSchedule(1)).thenAnswer((_) async => [
            _schedule(startDate: past.toIso8601String()),
          ]);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_schedule'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchSchedule(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [];
      });

      await pump(tester);
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(callCount, 2);
    });
  });

  group('ArtistSchedule 네비게이션', () {
    testWidgets('헤더를 탭하면 일정 전체 목록으로 이동한다', (tester) async {
      when(() => mockService.fetchSchedule(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('artist_schedule_title'.tr(args: ['아티스트'])));
      await tester.pumpAndSettle();

      expect(find.byType(ArtistScheduleListScreen), findsOneWidget);
    });
  });

  group('ArtistSchedule 새로고침', () {
    testWidgets('refresh를 호출하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchSchedule(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });
      final key = GlobalKey<ArtistScheduleState>();

      await pump(tester, key: key);
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
