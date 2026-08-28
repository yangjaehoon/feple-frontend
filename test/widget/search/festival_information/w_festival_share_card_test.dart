import 'package:feple/common/widget/w_day_badge.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_share_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../common/common_widget_test_harness.dart';

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

FestivalModel _poster({
  String title = '펜타포트',
  String location = '인천 송도달빛축제공원',
  String? startDate,
  String? endDate,
}) {
  return FestivalModel(
    id: 1,
    title: title,
    description: '',
    location: location,
    startDate: startDate ?? _fmtDate(DateTime.now().add(const Duration(days: 30))),
    endDate: endDate ?? _fmtDate(DateTime.now().add(const Duration(days: 32))),
    posterUrl: '',
  );
}

void main() {
  testWidgets('제목/날짜/장소를 보여준다', (tester) async {
    final poster = _poster(
      title: '펜타포트',
      location: '인천 송도달빛축제공원',
      startDate: '2099-08-01',
      endDate: '2099-08-03',
    );

    await pumpCommonWidget(tester, FestivalShareCard(poster: poster, isEnglish: false));

    expect(find.text('펜타포트'), findsOneWidget);
    expect(find.text('인천 송도달빛축제공원'), findsOneWidget);
    expect(find.text('2099-08-01 ~ 2099-08-03'), findsOneWidget);
  });

  testWidgets('진행 예정 페스티벌이면 D-day 배지를 보여준다', (tester) async {
    final poster = _poster(
      startDate: _fmtDate(DateTime.now().add(const Duration(days: 10))),
      endDate: _fmtDate(DateTime.now().add(const Duration(days: 12))),
    );

    await pumpCommonWidget(tester, FestivalShareCard(poster: poster, isEnglish: false));

    expect(find.byType(DayBadge), findsOneWidget);
  });

  testWidgets('종료된 페스티벌이면 D-day 배지를 보여주지 않는다', (tester) async {
    final poster = _poster(
      startDate: _fmtDate(DateTime.now().subtract(const Duration(days: 10))),
      endDate: _fmtDate(DateTime.now().subtract(const Duration(days: 5))),
    );

    await pumpCommonWidget(tester, FestivalShareCard(poster: poster, isEnglish: false));

    expect(find.byType(DayBadge), findsNothing);
  });

  testWidgets('FEPLE 브랜드 배지를 보여준다', (tester) async {
    await pumpCommonWidget(tester, FestivalShareCard(poster: _poster(), isEnglish: false));

    expect(find.text('FEPLE'), findsOneWidget);
  });
}
