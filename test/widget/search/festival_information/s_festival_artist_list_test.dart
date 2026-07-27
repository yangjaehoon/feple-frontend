import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_artist_list.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_artists_fetcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalArtistsFetcher extends Mock implements FestivalArtistsFetcher {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}

FestivalArtistItem _artist({
  int artistId = 1,
  String artistName = '아티스트',
  List<String> performanceDates = const [],
}) =>
    FestivalArtistItem(
      artistId: artistId,
      artistName: artistName,
      performanceDates: performanceDates,
    );

void main() {
  late MockFestivalArtistsFetcher mockFetcher;
  late MockArtistFollowService mockFollowService;

  setUp(() {
    mockFetcher = MockFestivalArtistsFetcher();
    mockFollowService = MockArtistFollowService();
    when(() => mockFollowService.fetchFollowingIds(any()))
        .thenAnswer((_) async => {});
  });

  FestivalArtistsNotifier makeNotifier() => FestivalArtistsNotifier(
        festivalId: 1,
        userId: 1,
        festivalService: mockFetcher,
        followService: mockFollowService,
      );

  Future<FestivalArtistsNotifier> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final notifier = makeNotifier();
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
            home: FestivalArtistListScreen(notifier: notifier),
          ),
        ),
      ),
    );
    await tester.pump();
    return notifier;
  }

  group('FestivalArtistListScreen 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<List<FestivalArtistItem>>();
      when(() => mockFetcher.fetchFestivalArtists(1))
          .thenAnswer((_) => completer.future);

      final notifier = await pump(tester);
      unawaited(notifier.fetch());
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget); // 스켈레톤 그리드
      completer.complete([]);
      await tester.pump();
    });
  });

  group('FestivalArtistListScreen 에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockFetcher.fetchFestivalArtists(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_artist(artistName: '복구된 아티스트')];
      });

      final notifier = await pump(tester);
      unawaited(notifier.fetch());
      await tester.pump();
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('복구된 아티스트'), findsOneWidget);
    });
  });

  group('FestivalArtistListScreen 빈 목록', () {
    testWidgets('아티스트가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockFetcher.fetchFestivalArtists(1)).thenAnswer((_) async => []);

      final notifier = await pump(tester);
      unawaited(notifier.fetch());
      await tester.pump();
      await tester.pump();

      expect(find.text('no_participating_artists'.tr()), findsOneWidget);
    });
  });

  group('FestivalArtistListScreen 목록', () {
    testWidgets('아티스트 그리드를 보여준다', (tester) async {
      when(() => mockFetcher.fetchFestivalArtists(1)).thenAnswer(
        (_) async => [_artist(artistId: 1, artistName: '아티스트A'), _artist(artistId: 2, artistName: '아티스트B')],
      );

      final notifier = await pump(tester);
      unawaited(notifier.fetch());
      await tester.pump();
      await tester.pump();

      expect(find.text('아티스트A'), findsOneWidget);
      expect(find.text('아티스트B'), findsOneWidget);

      // AnimatedListItem의 stagger 딜레이 타이머를 흘려보내 pending timer 어서션을 피한다
      await tester.pumpAndSettle();
    });

    testWidgets('날짜 필터가 있으면 날짜 탭을 보여주고 선택 시 필터링된다', (tester) async {
      when(() => mockFetcher.fetchFestivalArtists(1)).thenAnswer(
        (_) async => [
          _artist(artistId: 1, artistName: '아티스트A', performanceDates: ['2026-08-01']),
          _artist(artistId: 2, artistName: '아티스트B', performanceDates: ['2026-08-02']),
        ],
      );

      final notifier = await pump(tester);
      unawaited(notifier.fetch());
      await tester.pump();
      await tester.pump();

      expect(find.byType(DateTabBar), findsOneWidget);
      expect(find.text('아티스트A'), findsOneWidget);
      expect(find.text('아티스트B'), findsOneWidget);

      await tester.tap(find.text('8/1')); // DateTabBar 기본 포맷: yyyy-MM-dd → M/d
      await tester.pump();

      expect(find.text('아티스트A'), findsOneWidget);
      expect(find.text('아티스트B'), findsNothing);

      await tester.pumpAndSettle();
    });
  });

  group('FestivalArtistListScreen 새로고침', () {
    testWidgets('pull-to-refresh 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockFetcher.fetchFestivalArtists(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      final notifier = await pump(tester);
      unawaited(notifier.fetch());
      await tester.pump();
      await tester.pump();
      expect(callCount, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
