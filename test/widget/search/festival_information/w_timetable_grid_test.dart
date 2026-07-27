import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

TimetableEntry _entry({
  int id = 1,
  String stageName = 'Main',
  int stageOrder = 1,
  String artistName = '아티스트',
  String startTime = '15:00',
  String endTime = '16:00',
}) =>
    TimetableEntry(
      id: id,
      stageName: stageName,
      stageOrder: stageOrder,
      artistName: artistName,
      festivalDate: '2026-08-01',
      startTime: startTime,
      endTime: endTime,
    );

TimetableScrollControllers _controllers() => TimetableScrollControllers(
      hHeader: ScrollController(),
      hContent: ScrollController(),
      vContent: ScrollController(),
      vTime: ScrollController(),
    );

Future<void> _pump(WidgetTester tester, Widget grid) async {
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
            body: SizedBox(width: 400, child: grid),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TimetableGrid 렌더링', () {
    testWidgets('스테이지 이름과 공연 정보(이름/시간)를 보여준다', (tester) async {
      await _pump(
        tester,
        TimetableGrid(
          stages: const ['Main'],
          filtered: [_entry(artistName: '헤드라이너', startTime: '18:00', endTime: '19:00')],
          startHour: 12,
          endHour: 22,
          followedNames: const {},
          availableW: 400,
          scrollControllers: _controllers(),
        ),
      );

      expect(find.text('Main'), findsOneWidget);
      expect(find.text('헤드라이너'), findsOneWidget);
      expect(find.text('18:00 – 19:00'), findsOneWidget);
    });

    testWidgets('팔로우한 아티스트면 카드가 강조 색상으로 표시된다', (tester) async {
      await _pump(
        tester,
        TimetableGrid(
          stages: const ['Main'],
          filtered: [_entry(artistName: '팔로우아티스트')],
          startHour: 12,
          endHour: 22,
          followedNames: const {'팔로우아티스트'},
          availableW: 400,
          scrollControllers: _controllers(),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('팔로우아티스트'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('일정이 비어있어도 크래시 없이 렌더링된다', (tester) async {
      await _pump(
        tester,
        TimetableGrid(
          stages: const [],
          filtered: const [],
          startHour: 12,
          endHour: 22,
          followedNames: const {},
          availableW: 400,
          scrollControllers: _controllers(),
        ),
      );

      expect(find.byType(TimetableGrid), findsOneWidget);
    });
  });
}
