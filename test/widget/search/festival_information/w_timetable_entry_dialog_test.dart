import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/my_timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_entry_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

MyTimetableEntry _entry({
  String id = '1',
  String stageName = 'Main',
  String label = '',
  String startTime = '18:00',
  String endTime = '19:00',
}) {
  return MyTimetableEntry(
    id: id,
    stageName: stageName,
    label: label,
    startTime: startTime,
    endTime: endTime,
    colorValue: kUserScheduleColors.first.toARGB32(),
  );
}

Future<void> _openDialog(
  WidgetTester tester, {
  List<String> stages = const ['Main', 'Sub'],
  required MyTimetableEntry initial,
  required bool isEditing,
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
                onPressed: () => showDialog<TimetableEntryDialogResult>(
                  context: context,
                  builder: (_) => TimetableEntryDialog(
                    stages: stages,
                    initial: initial,
                    isEditing: isEditing,
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

void main() {
  group('TimetableEntryDialog 렌더링', () {
    testWidgets('추가 모드에서는 삭제 버튼이 없다', (tester) async {
      await _openDialog(tester, initial: _entry(), isEditing: false);

      expect(find.text('timetable_add_entry'.tr()), findsOneWidget);
      expect(find.text('msg_delete'.tr()), findsNothing);
    });

    testWidgets('편집 모드에서는 삭제 버튼이 보인다', (tester) async {
      await _openDialog(tester, initial: _entry(label: '기존 일정'), isEditing: true);

      expect(find.text('timetable_edit_entry'.tr()), findsOneWidget);
      expect(find.text('msg_delete'.tr()), findsOneWidget);
    });
  });

  group('TimetableEntryDialog 유효성 검사', () {
    testWidgets('이름이 비어있으면 저장 버튼이 비활성화된다', (tester) async {
      await _openDialog(tester, initial: _entry(label: ''), isEditing: false);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('이름을 입력하면 저장 버튼이 활성화된다', (tester) async {
      await _openDialog(tester, initial: _entry(label: ''), isEditing: false);

      // DropdownMenu 내부에도 TextField가 있어 이름 입력 필드는 첫 번째 것을 사용
      await tester.enterText(find.byType(TextField).first, '내 일정');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('종료 시각이 시작 시각보다 빠르면 에러 문구를 보여주고 저장이 비활성화된다', (tester) async {
      await _openDialog(
        tester,
        initial: _entry(label: '일정', startTime: '19:00', endTime: '18:00'),
        isEditing: false,
      );

      expect(find.text('timetable_invalid_time_range'.tr()), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('TimetableEntryDialog 저장/취소', () {
    testWidgets('저장하면 TimetableEntrySaved로 pop된다', (tester) async {
      TimetableEntryDialogResult? captured;
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
                    onPressed: () async {
                      captured = await showDialog<TimetableEntryDialogResult>(
                        context: context,
                        builder: (_) => TimetableEntryDialog(
                          stages: const ['Main'],
                          initial: _entry(label: ''),
                          isEditing: false,
                        ),
                      );
                    },
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

      await tester.enterText(find.byType(TextField).first, '헤드라이너');
      await tester.pump();
      await tester.tap(find.text('timetable_add'.tr()));
      await tester.pumpAndSettle();

      expect(captured, isA<TimetableEntrySaved>());
      expect((captured as TimetableEntrySaved).entry.label, '헤드라이너');
    });

    testWidgets('취소하면 null로 pop된다', (tester) async {
      await _openDialog(tester, initial: _entry(label: '일정'), isEditing: false);

      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(TimetableEntryDialog), findsNothing);
    });
  });

  group('TimetableEntryDialog 삭제', () {
    testWidgets('삭제를 확인하면 TimetableEntryDeleted로 pop된다', (tester) async {
      TimetableEntryDialogResult? captured;
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
                    onPressed: () async {
                      captured = await showDialog<TimetableEntryDialogResult>(
                        context: context,
                        builder: (_) => TimetableEntryDialog(
                          stages: const ['Main'],
                          initial: _entry(label: '삭제할 일정'),
                          isEditing: true,
                        ),
                      );
                    },
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

      await tester.tap(find.text('msg_delete'.tr()).first);
      await tester.pumpAndSettle();

      expect(find.text('timetable_delete_confirm'.tr()), findsOneWidget);
      await tester.tap(find.text('msg_delete'.tr()).last);
      await tester.pumpAndSettle();

      expect(captured, isA<TimetableEntryDeleted>());
    });
  });

  group('TimetableEntryDialog 색상 선택', () {
    testWidgets('색상을 선택하면 저장 결과에 반영된다', (tester) async {
      TimetableEntryDialogResult? captured;
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
                    onPressed: () async {
                      captured = await showDialog<TimetableEntryDialogResult>(
                        context: context,
                        builder: (_) => TimetableEntryDialog(
                          stages: const ['Main'],
                          initial: _entry(label: '일정'),
                          isEditing: false,
                        ),
                      );
                    },
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

      await tester.tap(find.bySemanticsLabel('select_color'.tr()).at(1));
      await tester.pump();
      await tester.tap(find.text('timetable_add'.tr()));
      await tester.pumpAndSettle();

      final saved = (captured as TimetableEntrySaved).entry;
      expect(saved.colorValue, kUserScheduleColors[1].toARGB32());
    });
  });
}
