import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_tap_loading_indicator.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_icon.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_schedule_list_tile.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}

ArtistScheduleModel _schedule({
  int festivalId = 1,
  String title = '일정',
  String? location,
  String? startDate,
  List<CoArtistInfo> coArtists = const [],
}) =>
    ArtistScheduleModel(
      festivalId: festivalId,
      title: title,
      location: location,
      startDate: startDate,
      eventType: EventType.festival,
      coArtists: coArtists,
    );

void main() {
  late MockFestivalService mockFestivalService;

  setUp(() {
    mockFestivalService = MockFestivalService();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
  });

  tearDown(() {
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
  });

  Future<void> pump(
    WidgetTester tester, {
    required ArtistScheduleModel item,
    VoidCallback? onTap,
    bool isLoading = false,
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
              body: ScheduleListTile(item: item, onTap: onTap, isLoading: isLoading),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ScheduleListTile 렌더링', () {
    testWidgets('제목, 장소, 날짜를 보여준다', (tester) async {
      await pump(
        tester,
        item: _schedule(title: '락 페스티벌', location: '서울', startDate: '2026-08-01'),
      );

      expect(find.text('락 페스티벌'), findsOneWidget);
      expect(find.text('서울'), findsOneWidget);
      expect(find.text('2026.08.01'), findsOneWidget);
    });

    testWidgets('함께 출연하는 아티스트를 보여준다', (tester) async {
      await pump(
        tester,
        item: _schedule(coArtists: const [
          CoArtistInfo(artistId: 2, artistName: '동반아티스트'),
        ]),
      );

      expect(find.byTooltip('동반아티스트'), findsOneWidget);
    });

    testWidgets('isLoading이면 로딩 인디케이터를 보여준다', (tester) async {
      await pump(tester, item: _schedule(), isLoading: true);

      expect(find.byType(TapLoadingIndicator), findsOneWidget);
    });
  });

  group('ScheduleListTile 탭', () {
    testWidgets('행을 탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await pump(tester, item: _schedule(), onTap: () => tapped = true);

      await tester.tap(find.byType(ScheduleListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('포스터를 탭하면 페스티벌 정보를 조회하고 로딩 상태로 바뀐다', (tester) async {
      when(() => mockFestivalService.fetchById(1))
          .thenAnswer((_) => Completer<FestivalModel>().future);

      await pump(tester, item: _schedule(festivalId: 1));

      await tester.tap(find.byType(EventTypeIcon));
      await tester.pump();

      verify(() => mockFestivalService.fetchById(1)).called(1);
      expect(find.byType(TapLoadingIndicator), findsOneWidget);
    });

    testWidgets('페스티벌 조회 실패 시 에러 스낵바를 보여준다', (tester) async {
      when(() => mockFestivalService.fetchById(1))
          .thenAnswer((_) async => throw Exception('네트워크 오류'));

      await pump(tester, item: _schedule(festivalId: 1));

      await tester.tap(find.byType(EventTypeIcon));
      await tester.pumpAndSettle();

      expect(find.text('err_fetch_data'.tr()), findsOneWidget);
    });
  });
}
