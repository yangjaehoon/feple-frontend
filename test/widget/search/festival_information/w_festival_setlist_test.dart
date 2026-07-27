import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_setlist_fullscreen.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_setlist.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalDetailService extends Mock implements FestivalDetailService {}

SongModel _song({int id = 1, String title = '노래'}) => SongModel(
      id: id,
      title: title,
      youtubeVideoId: 'abc123',
      youtubeUrl: 'https://youtube.com/watch?v=abc123',
    );

FestivalSetlistEntry _entry({
  int artistFestivalId = 1,
  int artistId = 1,
  String artistName = '아티스트',
  List<SongModel> songs = const [],
}) =>
    FestivalSetlistEntry(
      artistFestivalId: artistFestivalId,
      artistId: artistId,
      artistName: artistName,
      songs: songs,
    );

void main() {
  late MockFestivalDetailService mockService;

  setUp(() {
    mockService = MockFestivalDetailService();
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
    sl.registerSingleton<FestivalDetailService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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
            home: Scaffold(body: FestivalSetlist(festivalId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FestivalSetlist 렌더링', () {
    testWidgets('아티스트와 대표곡을 보여준다', (tester) async {
      when(() => mockService.fetchSetlist(1)).thenAnswer(
        (_) async => [_entry(artistName: '헤드라이너', songs: [_song(title: '대표곡')])],
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('헤드라이너'), findsOneWidget);
      expect(find.text('대표곡'), findsOneWidget);
    });

    testWidgets('셋리스트가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistName: '아티스트', songs: [])]);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_setlist'.tr()), findsWidgets);
    });

    testWidgets('전체 셋리스트가 없으면 빈 상태를 보여준다', (tester) async {
      when(() => mockService.fetchSetlist(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_setlist'.tr()), findsOneWidget);
    });

    testWidgets('5명을 초과하면 더보기 버튼을 보여준다', (tester) async {
      when(() => mockService.fetchSetlist(1)).thenAnswer(
        (_) async => List.generate(7, (i) => _entry(artistId: i, artistFestivalId: i, artistName: '아티스트$i')),
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('see_more'.tr()), findsOneWidget);
    });
  });

  group('FestivalSetlist 에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchSetlist(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_entry(artistName: '복구된 아티스트')];
      });

      await pump(tester);
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('복구된 아티스트'), findsOneWidget);
    });
  });

  group('FestivalSetlist 네비게이션', () {
    testWidgets('전체보기를 탭하면 전체화면으로 이동한다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistName: '아티스트')]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('view_all'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(FestivalSetlistFullscreenScreen), findsOneWidget);
    });
  });

  group('FestivalSetlist 새로고침', () {
    testWidgets('refresh() 호출 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchSetlist(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      final key = GlobalKey<FestivalSetlistState>();
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
              home: Scaffold(body: FestivalSetlist(key: key, festivalId: 1)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(callCount, 1);

      key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
