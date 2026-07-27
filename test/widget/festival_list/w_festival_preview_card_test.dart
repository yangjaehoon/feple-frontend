import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _isoDate(int daysFromNow) =>
    DateTime.now().add(Duration(days: daysFromNow)).toIso8601String();

FestivalPreview _festival({
  int id = 1,
  String title = '테스트 페스티벌',
  String location = '서울 올림픽공원',
  String? startDate,
  String? endDate,
}) {
  return FestivalPreview(
    id: id,
    title: title,
    location: location,
    posterUrl: '',
    startDate: startDate ?? _isoDate(3),
    endDate: endDate,
  );
}

Future<void> _pump(WidgetTester tester, FestivalPreview festival) async {
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
          home: Scaffold(body: FestivalPreviewCard(festival: festival)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('FestivalPreviewCard 렌더링', () {
    testWidgets('제목/장소/시작일을 보여준다', (tester) async {
      await _pump(
        tester,
        _festival(title: '락페스티벌', location: '인천 송도', startDate: _isoDate(3)),
      );

      expect(find.text('락페스티벌'), findsOneWidget);
      expect(find.text('인천 송도'), findsOneWidget);
    });

    testWidgets('진행중이 아니고 시작일이 있으면 D-day 뱃지를 보여준다', (tester) async {
      await _pump(tester, _festival(startDate: _isoDate(5)));

      expect(find.byType(DayBadge), findsOneWidget);
      expect(find.text('D-5'), findsOneWidget);
    });

    testWidgets('종료된 페스티벌이면 종료 오버레이를 보여주고 D-day 뱃지는 숨긴다', (tester) async {
      await _pump(
        tester,
        _festival(startDate: _isoDate(-30), endDate: _isoDate(-10)),
      );

      expect(find.text('status_ended'.tr()), findsOneWidget);
      expect(find.byType(DayBadge), findsNothing);
    });
  });
}
