import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/dart/extension/datetime_extension.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_timetable_fullscreen.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_timetable.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_grid.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalDetailService extends Mock implements FestivalDetailService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}
class MockUserProvider extends Mock implements UserProvider {}

// selectedDate 기본값이 오늘 날짜와 겹치면(dates.contains(today)) 첫날 대신
// 오늘이 선택되어 버려 고정 리터럴 날짜는 시간이 지나면서 깨짐 — 항상 미래로 고정.
final _day1 = DateTime.now().add(const Duration(days: 30)).toYMD;
final _day2 = DateTime.now().add(const Duration(days: 31)).toYMD;

TimetableEntry _entry({
  int id = 1,
  String stageName = 'Main',
  int stageOrder = 1,
  String artistName = 'Artist',
  String? festivalDate,
  String startTime = '15:00',
  String endTime = '16:00',
}) =>
    TimetableEntry(
      id: id,
      stageName: stageName,
      stageOrder: stageOrder,
      artistName: artistName,
      festivalDate: festivalDate ?? _day1,
      startTime: startTime,
      endTime: endTime,
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  late MockFestivalDetailService mockDetailService;
  late MockArtistFollowService mockFollowService;

  setUp(() {
    mockDetailService = MockFestivalDetailService();
    mockFollowService = MockArtistFollowService();
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
    sl.registerSingleton<FestivalDetailService>(mockDetailService);
    if (sl.isRegistered<ArtistFollowService>()) {
      sl.unregister<ArtistFollowService>();
    }
    sl.registerSingleton<ArtistFollowService>(mockFollowService);
    when(() => mockFollowService.fetchFollowedArtistNames(any()))
        .thenAnswer((_) async => {});
  });

  tearDown(() {
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
    if (sl.isRegistered<ArtistFollowService>()) {
      sl.unregister<ArtistFollowService>();
    }
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userProvider = MockUserProvider();
    when(() => userProvider.currentUserId).thenReturn(1);

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
          child: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: MaterialApp(
              home: Scaffold(
                body: FestivalTimetable(
                  festivalId: 1,
                  startDate: _day1,
                  endDate: _day2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FestivalTimetable 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      when(() => mockDetailService.fetchTimetable(1)).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 50), () => []),
      );

      await pump(tester);

      expect(find.byType(TimetableGrid), findsNothing);

      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('FestivalTimetable 에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockDetailService.fetchTimetable(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_entry()];
      });

      await pump(tester);
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.byType(TimetableGrid), findsOneWidget);
    });
  });

  group('FestivalTimetable 빈 목록', () {
    testWidgets('일정이 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockDetailService.fetchTimetable(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_timetable'.tr()), findsOneWidget);
    });
  });

  group('FestivalTimetable 목록', () {
    testWidgets('일정이 있으면 그리드와 날짜 탭, 전체화면 버튼을 보여준다', (tester) async {
      when(() => mockDetailService.fetchTimetable(1))
          .thenAnswer((_) async => [_entry(festivalDate: _day1)]);

      await pump(tester);
      await tester.pump();

      expect(find.byType(TimetableGrid), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
    });

    testWidgets('전체화면 버튼을 탭하면 전체화면 타임테이블로 이동한다', (tester) async {
      when(() => mockDetailService.fetchTimetable(1))
          .thenAnswer((_) async => [_entry(festivalDate: _day1)]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.open_in_full_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TimetableFullscreenScreen), findsOneWidget);
    });
  });

  group('FestivalTimetable 날짜 범위 갱신', () {
    // FestivalInformationFragment가 상세 재조회 후 최신 startDate/endDate를
    // 다시 넘겨줄 때, 이 위젯이 실제로 새 날짜 탭을 그리는지 검증한다 —
    // entries 재조회 없이 TimetableNotifier.updateDateRange만으로 반영돼야 함.
    testWidgets('startDate/endDate가 바뀌면 날짜 탭이 새 범위로 다시 그려진다', (tester) async {
      when(() => mockDetailService.fetchTimetable(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text(_day1), findsOneWidget);

      final newDay1 = DateTime.now().add(const Duration(days: 60)).toYMD;
      final newDay2 = DateTime.now().add(const Duration(days: 61)).toYMD;
      final userProvider = MockUserProvider();
      when(() => userProvider.currentUserId).thenReturn(1);

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
            child: ChangeNotifierProvider<UserProvider>.value(
              value: userProvider,
              child: MaterialApp(
                home: Scaffold(
                  body: FestivalTimetable(
                    festivalId: 1,
                    startDate: newDay1,
                    endDate: newDay2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(newDay1), findsOneWidget);
      expect(find.text(_day1), findsNothing);
      // 날짜 범위만 바뀐 것이므로 entries는 다시 조회하지 않는다
      verify(() => mockDetailService.fetchTimetable(1)).called(1);
    });
  });

  group('FestivalTimetable 연동 스크롤', () {
    // linked_scroll_controller로 얼어붙은 헤더(가로)·시간축(세로)을 본문에
    // 묶었으므로, 본문을 드래그하면 두 축이 각각 같은 양만큼 따라 움직여야 한다.
    testWidgets('본문을 드래그하면 헤더와 시간축이 같은 양만큼 함께 움직인다', (tester) async {
      // 스테이지 5개 + 12~22시 범위 → 그리드가 가로/세로 모두 뷰포트보다 커서
      // 양방향 스크롤이 활성화되도록 좁은 뷰포트로 띄운다.
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entries = [
        for (var i = 0; i < 5; i++)
          _entry(
            id: i + 1,
            stageName: 'Stage${i + 1}',
            stageOrder: i + 1,
            artistName: 'Perf${i + 1}',
            startTime: '12:00',
            endTime: '13:00',
          ),
        _entry(
          id: 99,
          stageName: 'Stage1',
          stageOrder: 1,
          artistName: 'LatePerf',
          startTime: '21:00',
          endTime: '22:00',
        ),
      ];
      when(() => mockDetailService.fetchTimetable(1))
          .thenAnswer((_) async => entries);

      await EasyLocalization.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final userProvider = MockUserProvider();
      when(() => userProvider.currentUserId).thenReturn(1);

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
            child: ChangeNotifierProvider<UserProvider>.value(
              value: userProvider,
              child: MaterialApp(
                home: Scaffold(
                  body: FestivalTimetable(
                    festivalId: 1,
                    startDate: _day1,
                    endDate: _day2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(TimetableGrid), findsOneWidget);

      // 가로 연동: 본문을 왼쪽으로 드래그 → 헤더 셀도 같은 dx만큼 이동
      final headerBefore = tester.getTopLeft(find.text('Stage1')).dx;
      await tester.drag(find.text('Perf3'), const Offset(-120, 0));
      await tester.pumpAndSettle();
      final headerAfter = tester.getTopLeft(find.text('Stage1')).dx;
      expect(headerAfter, lessThan(headerBefore - 50));

      // 세로 연동: 본문을 위로 드래그 → 시간축 라벨도 같은 dy만큼 이동
      final timeBefore = tester.getTopLeft(find.text('12:00')).dy;
      await tester.drag(find.text('Perf3'), const Offset(0, -100));
      await tester.pumpAndSettle();
      final timeAfter = tester.getTopLeft(find.text('12:00')).dy;
      expect(timeAfter, lessThan(timeBefore - 40));
    });
  });

  group('FestivalTimetable 새로고침', () {
    testWidgets('refresh() 호출 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockDetailService.fetchTimetable(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      final key = GlobalKey<FestivalTimetableState>();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      final userProvider = MockUserProvider();
      when(() => userProvider.currentUserId).thenReturn(1);

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
            child: ChangeNotifierProvider<UserProvider>.value(
              value: userProvider,
              child: MaterialApp(
                home: Scaffold(
                  body: FestivalTimetable(
                    key: key,
                    festivalId: 1,
                    startDate: _day1,
                    endDate: _day2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
