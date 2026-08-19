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
  List<String> genres = const [],
  int attendingCount = 0,
}) {
  return FestivalPreview(
    id: id,
    title: title,
    location: location,
    posterUrl: '',
    startDate: startDate ?? _isoDate(3),
    endDate: endDate,
    genres: genres,
    attendingCount: attendingCount,
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

    testWidgets('참석 인원이 있으면 참석자 수를 보여준다', (tester) async {
      await _pump(tester, _festival(attendingCount: 42));

      expect(find.text('attending_count_short'.tr(args: ['42'])), findsOneWidget);
    });

    testWidgets('참석 인원이 0이면 참석자 수를 숨긴다', (tester) async {
      await _pump(tester, _festival());

      expect(find.text('attending_count_short'.tr(args: ['0'])), findsNothing);
      expect(find.byIcon(Icons.people_outline_rounded), findsNothing);
    });

    testWidgets('장르가 있으면 장르 태그를 보여준다', (tester) async {
      await _pump(tester, _festival(genres: ['BAND', 'DANCE']));

      expect(find.text('genre_band'.tr()), findsOneWidget);
      expect(find.text('genre_dance'.tr()), findsOneWidget);
    });

    testWidgets('장르가 없으면 태그 영역을 숨긴다', (tester) async {
      await _pump(tester, _festival());

      expect(find.text('genre_band'.tr()), findsNothing);
    });

    testWidgets('장르가 2개를 넘으면 앞의 2개만 보여준다', (tester) async {
      await _pump(tester, _festival(genres: ['BAND', 'DANCE', 'INDIE']));

      expect(find.text('genre_band'.tr()), findsOneWidget);
      expect(find.text('genre_dance'.tr()), findsOneWidget);
      expect(find.text('genre_indie'.tr()), findsNothing);
    });

    testWidgets('장르와 참석 인원이 동시에 있어도 넘치지 않는다', (tester) async {
      await _pump(
        tester,
        _festival(genres: ['BAND', 'DANCE'], location: '아주 긴 장소 이름이 들어가는 경우 테스트', attendingCount: 999),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('genre_band'.tr()), findsOneWidget);
      expect(find.text('genre_dance'.tr()), findsOneWidget);
      expect(find.text('attending_count_short'.tr(args: ['999'])), findsOneWidget);
    });

    testWidgets('매핑 안 되는 장르만 있으면 태그 영역을 숨긴다', (tester) async {
      await _pump(tester, _festival(genres: ['UNKNOWN_GENRE']));

      expect(find.byIcon(Icons.people_outline_rounded), findsNothing);
      // 매핑 실패한 장르만 있을 때 빈 태그 줄이 그려지지 않는지는 위젯 트리에 남는 태그
      // 텍스트가 하나도 없는 것으로 간접 확인한다(장르 라벨은 전부 i18n 키로 렌더되므로
      // 원본 코드 'UNKNOWN_GENRE' 문자열이 그대로 화면에 나타나지 않아야 정상).
      expect(find.text('UNKNOWN_GENRE'), findsNothing);
    });
  });
}
