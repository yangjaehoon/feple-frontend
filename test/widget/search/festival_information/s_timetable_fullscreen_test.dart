import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_timetable_fullscreen.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_entry_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

TimetableEntry _entry({
  int id = 1,
  String stageName = 'Main',
  int stageOrder = 1,
  String artistName = '아티스트',
  String festivalDate = '2026-08-01',
  String startTime = '18:00',
  String endTime = '19:00',
}) =>
    TimetableEntry(
      id: id,
      stageName: stageName,
      stageOrder: stageOrder,
      artistName: artistName,
      festivalDate: festivalDate,
      startTime: startTime,
      endTime: endTime,
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  Future<void> pump(
    WidgetTester tester, {
    required List<TimetableEntry> entries,
    List<String> dates = const ['2026-08-01'],
    String? initialDate = '2026-08-01',
  }) async {
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
            home: TimetableFullscreenScreen(
              festivalId: 1,
              entries: entries,
              followedNames: const {},
              dates: dates,
              initialDate: initialDate,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('TimetableFullscreenScreen 렌더링', () {
    testWidgets('일정이 있으면 아티스트명을 보여준다', (tester) async {
      await pump(tester, entries: [_entry(artistName: '헤드라이너')]);

      expect(find.text('헤드라이너'), findsOneWidget);
    });

    testWidgets('일정이 없으면 안내 문구를 보여준다', (tester) async {
      await pump(tester, entries: []);

      expect(find.text('no_timetable'.tr()), findsOneWidget);
    });

    testWidgets('날짜가 여러 개면 날짜 탭을 보여주고 전환할 수 있다', (tester) async {
      await pump(
        tester,
        entries: [
          _entry(id: 1, artistName: '8월1일아티스트', festivalDate: '2026-08-01'),
          _entry(id: 2, artistName: '8월2일아티스트', festivalDate: '2026-08-02'),
        ],
        dates: ['2026-08-01', '2026-08-02'],
      );

      expect(find.text('8월1일아티스트'), findsOneWidget);
      expect(find.text('8월2일아티스트'), findsNothing);

      await tester.tap(find.text('2026-08-02'));
      await tester.pump();

      expect(find.text('8월1일아티스트'), findsNothing);
      expect(find.text('8월2일아티스트'), findsOneWidget);
    });
  });

  group('TimetableFullscreenScreen 닫기', () {
    testWidgets('닫기 버튼을 탭하면 화면이 닫힌다', (tester) async {
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 화면 자체가 유일한 route면 Navigator.pop()이 아무 효과가 없으므로
      // 실제 사용처럼 트리거 화면에서 push해 진입시킨다.
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TimetableFullscreenScreen(
                          festivalId: 1,
                          entries: [_entry()],
                          followedNames: const {},
                          dates: const ['2026-08-01'],
                          initialDate: '2026-08-01',
                        ),
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

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TimetableFullscreenScreen), findsNothing);
    });
  });

  group('TimetableFullscreenScreen 내 일정 추가', () {
    testWidgets('추가 버튼을 탭하면 다이얼로그가 열리고 저장하면 목록에 반영된다', (tester) async {
      await pump(tester, entries: [_entry(stageName: 'Main')]);

      await tester.tap(find.text('timetable_add'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(TimetableEntryDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '내가 만든 일정');
      await tester.pump();
      await tester.tap(find.text('timetable_add'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.text('내가 만든 일정'), findsOneWidget);
    });
  });

  group('TimetableFullscreenScreen 내 일정 수정/삭제', () {
    testWidgets('내 일정을 탭하면 편집 다이얼로그가 열리고 삭제하면 목록에서 사라진다', (tester) async {
      await pump(tester, entries: [_entry(stageName: 'Main')]);

      await tester.tap(find.text('timetable_add'.tr()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '삭제될 일정');
      await tester.pump();
      await tester.tap(find.text('timetable_add'.tr()).last);
      await tester.pumpAndSettle();
      expect(find.text('삭제될 일정'), findsOneWidget);

      await tester.tap(find.text('삭제될 일정'));
      await tester.pumpAndSettle();
      expect(find.byType(TimetableEntryDialog), findsOneWidget);

      await tester.tap(find.text('msg_delete'.tr()).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('msg_delete'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.text('삭제될 일정'), findsNothing);
    });
  });
}
