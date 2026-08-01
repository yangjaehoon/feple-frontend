import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_artist_list.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artists.dart';
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
    when(() => mockFollowService.fetchFollowingIds(any()))
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
            child: const MaterialApp(
              home: Scaffold(body: FestivalArtists(festivalId: 1)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FestivalArtists 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      when(() => mockDetailService.fetchFestivalArtists(1)).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 50), () => []),
      );

      await pump(tester);

      expect(find.text('participating_artists'.tr()), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('FestivalArtists 에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockDetailService.fetchFestivalArtists(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_artist(artistName: '복구된 아티스트')];
      });

      await pump(tester);
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('복구된 아티스트'), findsOneWidget);
    });
  });

  group('FestivalArtists 빈 목록', () {
    testWidgets('참여 아티스트가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockDetailService.fetchFestivalArtists(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_participating_artists'.tr()), findsOneWidget);
    });
  });

  group('FestivalArtists 목록', () {
    testWidgets('아티스트 목록을 보여준다', (tester) async {
      when(() => mockDetailService.fetchFestivalArtists(1)).thenAnswer(
        (_) async => [_artist(artistId: 1, artistName: '아티스트A'), _artist(artistId: 2, artistName: '아티스트B')],
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('아티스트A'), findsOneWidget);
      expect(find.text('아티스트B'), findsOneWidget);
      expect(find.byType(DateTabBar), findsNothing);
    });

    testWidgets('공연일이 여러 개면 날짜 탭을 보여준다', (tester) async {
      when(() => mockDetailService.fetchFestivalArtists(1)).thenAnswer(
        (_) async => [
          _artist(artistId: 1, artistName: '아티스트A', performanceDates: ['2026-08-01']),
          _artist(artistId: 2, artistName: '아티스트B', performanceDates: ['2026-08-02']),
        ],
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('lineup_all'.tr()), findsOneWidget);
    });

    testWidgets('10명을 초과하면 더보기 항목을 보여주고 탭하면 전체 목록으로 이동한다', (tester) async {
      when(() => mockDetailService.fetchFestivalArtists(1)).thenAnswer(
        (_) async => List.generate(12, (i) => _artist(artistId: i, artistName: '아티스트$i')),
      );

      await pump(tester);
      await tester.pump();

      // BoardCardHeader에도 동일 라벨의 '더보기'가 있어 2개가 보인다 —
      // 마지막 항목이 아티스트 행의 더보기 카드
      expect(find.text('see_more'.tr()), findsNWidgets(2));

      await tester.tap(find.text('see_more'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.byType(FestivalArtistListScreen), findsOneWidget);
    });
  });

  group('FestivalArtists 헤더 네비게이션', () {
    testWidgets('헤더를 탭하면 전체 아티스트 목록 화면으로 이동한다', (tester) async {
      when(() => mockDetailService.fetchFestivalArtists(1))
          .thenAnswer((_) async => [_artist(artistName: '아티스트A')]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('participating_artists'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(FestivalArtistListScreen), findsOneWidget);
    });
  });

  group('FestivalArtists 새로고침', () {
    testWidgets('refresh() 호출 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockDetailService.fetchFestivalArtists(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      final key = GlobalKey<FestivalArtistsState>();
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
                home: Scaffold(body: FestivalArtists(key: key, festivalId: 1)),
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
