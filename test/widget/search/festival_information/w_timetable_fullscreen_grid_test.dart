import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/my_timetable_entry.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_fullscreen_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

TimetableEntry _entry({
  int id = 1,
  String stageName = 'StageA',
  int stageOrder = 0,
  String artistName = '아티스트',
  String startTime = '12:00',
  String endTime = '13:00',
}) =>
    TimetableEntry(
      id: id,
      stageName: stageName,
      stageOrder: stageOrder,
      artistName: artistName,
      festivalDate: '2099-08-01',
      startTime: startTime,
      endTime: endTime,
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    await Prefs.showCurrentTimeLine.set(false);
  });

  Future<void> pump(
    WidgetTester tester, {
    required TimetableRange range,
    List<MyTimetableEntry> userEntries = const [],
    Set<String> followedNames = const {},
    String? selectedDate = '2099-08-01',
    void Function(String stage, String startTime)? onTapGrid,
    void Function(MyTimetableEntry entry)? onTapMyTimetableEntry,
  }) async {
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
              body: SizedBox(
                width: 700,
                height: 500,
                child: TimetableFullscreenGrid(
                  range: range,
                  userEntries: userEntries,
                  followedNames: followedNames,
                  selectedDate: selectedDate,
                  onTapGrid: onTapGrid ?? (_, _) {},
                  onTapMyTimetableEntry: onTapMyTimetableEntry ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('TimetableFullscreenGrid 렌더링', () {
    testWidgets('공식 라인업 항목의 아티스트명을 보여준다', (tester) async {
      final range = TimetableRange(
        filtered: [_entry(artistName: '헤드라이너')],
        stages: const ['StageA'],
        startHour: 12,
        endHour: 14,
      );

      await pump(tester, range: range);

      expect(find.text('헤드라이너'), findsOneWidget);
    });

    testWidgets('운영 항목은 모든 스테이지 열에 표시된다', (tester) async {
      final range = TimetableRange(
        filtered: [
          _entry(stageName: '📢', artistName: '점심시간', startTime: '12:00', endTime: '12:30'),
        ],
        stages: const ['StageA', 'StageB'],
        startHour: 12,
        endHour: 14,
      );

      await pump(tester, range: range);

      expect(find.text('점심시간'), findsNWidgets(2));
    });

    testWidgets('내 일정 항목의 라벨을 보여준다', (tester) async {
      final range = TimetableRange(
        filtered: const [],
        stages: const ['StageA'],
        startHour: 12,
        endHour: 14,
      );
      final userEntry = MyTimetableEntry(
        id: 'u1',
        stageName: 'StageA',
        label: '내 일정',
        startTime: '12:30',
        endTime: '13:00',
        colorValue: 0xFF00FF00,
      );

      await pump(tester, range: range, userEntries: [userEntry]);

      expect(find.text('내 일정'), findsOneWidget);
    });
  });

  group('TimetableFullscreenGrid 탭', () {
    testWidgets('그리드를 탭하면 스테이지와 시각으로 onTapGrid가 호출된다', (tester) async {
      String? tappedStage;
      String? tappedTime;
      final range = TimetableRange(
        filtered: const [],
        stages: const ['StageA'],
        startHour: 12,
        endHour: 14,
      );

      await pump(
        tester,
        range: range,
        onTapGrid: (stage, time) {
          tappedStage = stage;
          tappedTime = time;
        },
      );

      final gestureDetector = find.descendant(
        of: find.byType(TimetableFullscreenGrid),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(gestureDetector);
      await tester.pump();

      expect(tappedStage, 'StageA');
      expect(tappedTime, isNotNull);
    });

    testWidgets('내 일정 카드를 탭하면 onTapMyTimetableEntry가 호출된다', (tester) async {
      MyTimetableEntry? tapped;
      final range = TimetableRange(
        filtered: const [],
        stages: const ['StageA'],
        startHour: 12,
        endHour: 14,
      );
      final userEntry = MyTimetableEntry(
        id: 'u1',
        stageName: 'StageA',
        label: '내 일정',
        startTime: '12:30',
        endTime: '13:00',
        colorValue: 0xFF00FF00,
      );

      await pump(
        tester,
        range: range,
        userEntries: [userEntry],
        onTapMyTimetableEntry: (entry) => tapped = entry,
      );

      await tester.tap(find.text('내 일정'));
      await tester.pump();

      expect(tapped?.id, 'u1');
    });
  });
}
