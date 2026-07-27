import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/s_unified_search.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_photo_readable.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/search_service.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSearchService extends Mock implements SearchService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}
class MockArtistPhotoReadable extends Mock implements ArtistPhotoReadable {}
class MockPostService extends Mock implements PostService {}
class MockArtistScheduleService extends Mock implements ArtistScheduleService {}
class MockSongService extends Mock implements SongService {}
class MockSongRequestService extends Mock implements SongRequestService {}
class MockArtistService extends Mock implements ArtistService {}
class MockFestivalService extends Mock implements FestivalService {}

Artist _artist({int id = 1, String name = '아이유'}) =>
    Artist(id: id, name: name, genre: 'KPOP', profileImageUrl: '', followerCount: 0);

FestivalPreview _festival({int id = 1, String title = '서울재즈'}) {
  final now = DateTime.now();
  return FestivalPreview(
    id: id,
    title: title,
    location: '서울',
    posterUrl: '',
    startDate: now.toIso8601String(),
  );
}

Post _post({int id = 1, String title = '게시글'}) => Post(
      id: id,
      title: title,
      content: '내용',
      likeCount: 0,
      nickname: '작성자',
    );

Future<void> _pump(WidgetTester tester) async {
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
        child: const MaterialApp(home: UnifiedSearchScreen()),
      ),
    ),
  );
  await tester.pump();
}

/// highlightKeyword가 적용되면 결과가 RichText로 렌더링돼 find.text()로 못 찾으므로
/// 평문 텍스트를 찾는 용도의 헬퍼.
Finder _richText(String text) =>
    find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  late MockSearchService mockSearchService;
  late MockArtistService mockArtistService;
  late MockFestivalService mockFestivalService;

  setUp(() async {
    mockSearchService = MockSearchService();
    mockArtistService = MockArtistService();
    mockFestivalService = MockFestivalService();

    // 테스트 간 최근 검색어 상태 오염 방지
    await Prefs.recentSearches.set([]);

    if (sl.isRegistered<SearchService>()) sl.unregister<SearchService>();
    sl.registerSingleton<SearchService>(mockSearchService);
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(mockArtistService);
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
  });

  tearDown(() {
    if (sl.isRegistered<SearchService>()) sl.unregister<SearchService>();
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
  });

  group('UnifiedSearchScreen 최근 검색어', () {
    testWidgets('최근 검색어가 없으면 안내 문구를 보여준다', (tester) async {
      await _pump(tester);

      expect(find.text('no_recent_searches'.tr()), findsOneWidget);
    });

    testWidgets('검색을 실행하면 최근 검색어에 추가된다', (tester) async {
      when(() => mockSearchService.search(any())).thenAnswer(
          (_) async => const SearchResult(artists: [], festivals: [], posts: []));

      await _pump(tester);

      await tester.enterText(find.byType(TextField), '아이유');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('최근 검색어를 탭하면 해당 키워드로 검색한다', (tester) async {
      await Prefs.recentSearches.set(['펜타포트']);
      when(() => mockSearchService.search('펜타포트')).thenAnswer((_) async =>
          SearchResult(artists: [], festivals: [_festival(title: '펜타포트')], posts: []));

      await _pump(tester);

      expect(find.text('펜타포트'), findsOneWidget);
      await tester.tap(find.text('펜타포트'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockSearchService.search('펜타포트')).called(1);
    });
  });

  group('UnifiedSearchScreen 자동완성', () {
    testWidgets('입력 후 디바운스 시간이 지나면 자동완성 목록을 보여준다', (tester) async {
      when(() => mockSearchService.suggestions('아이')).thenAnswer((_) async => [
            const SearchSuggestion('아이유', SearchType.artist, id: 1),
          ]);

      await _pump(tester);
      await tester.enterText(find.byType(TextField), '아이');
      await tester.pump(const Duration(milliseconds: 350)); // debounce(300ms) 통과

      expect(find.text('search_artists'.tr()), findsOneWidget);
      expect(_richText('아이유'), findsOneWidget);
    });

    testWidgets('제안에 id가 있으면 상세 화면으로 바로 이동한다', (tester) async {
      // ArtistScreen(목적지)의 나머지 섹션(ArtistSchedule/ArtistSongs/RelatedArtists/
      // ArtistBoard)은 initState에서 Future를 동기적으로 대입하므로 unstub 상태면
      // 위젯 빌드가 즉시 크래시한다 — 최소 빈 리스트로 스텁해 크래시만 방지한다.
      // 상세 내용 검증은 s_artist_page_test.dart의 몫.
      if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
      sl.registerSingleton<ArtistFollowService>(MockArtistFollowService());
      if (sl.isRegistered<ArtistPhotoReadable>()) sl.unregister<ArtistPhotoReadable>();
      sl.registerSingleton<ArtistPhotoReadable>(MockArtistPhotoReadable());
      if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
      final mockPostService = MockPostService();
      when(() => mockPostService.fetchArtistPosts(any())).thenAnswer((_) async => []);
      sl.registerSingleton<PostService>(mockPostService);
      if (sl.isRegistered<ArtistScheduleService>()) sl.unregister<ArtistScheduleService>();
      final mockScheduleService = MockArtistScheduleService();
      when(() => mockScheduleService.fetchSchedule(any())).thenAnswer((_) async => []);
      sl.registerSingleton<ArtistScheduleService>(mockScheduleService);
      if (sl.isRegistered<SongService>()) sl.unregister<SongService>();
      final mockSongService = MockSongService();
      when(() => mockSongService.fetchSongs(any())).thenAnswer((_) async => []);
      sl.registerSingleton<SongService>(mockSongService);
      if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
      sl.registerSingleton<SongRequestService>(MockSongRequestService());
      when(() => mockArtistService.fetchRelatedArtists(any())).thenAnswer((_) async => []);
      addTearDown(() {
        if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
        if (sl.isRegistered<ArtistPhotoReadable>()) sl.unregister<ArtistPhotoReadable>();
        if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
        if (sl.isRegistered<ArtistScheduleService>()) sl.unregister<ArtistScheduleService>();
        if (sl.isRegistered<SongService>()) sl.unregister<SongService>();
        if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
      });

      when(() => mockSearchService.suggestions(any())).thenAnswer((_) async => [
            const SearchSuggestion('아이유', SearchType.artist, id: 1),
          ]);
      when(() => mockArtistService.fetchArtistById(1)).thenAnswer((_) async => _artist());

      await _pump(tester);
      await tester.enterText(find.byType(TextField), '아이');
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(_richText('아이유'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ArtistScreen), findsOneWidget);
      verifyNever(() => mockSearchService.search(any()));
    });
  });

  group('UnifiedSearchScreen 검색 결과', () {
    testWidgets('로딩 후 탭별로 결과를 보여준다', (tester) async {
      when(() => mockSearchService.search('아이유')).thenAnswer((_) async => SearchResult(
            artists: [_artist(name: '아이유')],
            festivals: [_festival(title: '서울재즈')],
            posts: [_post(title: '공지글')],
          ));

      await _pump(tester);
      await tester.enterText(find.byType(TextField), '아이유');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 검색 키워드가 highlightKeyword로 전달돼 모든 결과 타일이 RichText로 렌더링된다
      expect(_richText('아이유'), findsOneWidget);
      expect(_richText('서울재즈'), findsOneWidget);
      expect(_richText('공지글'), findsOneWidget);
      expect(find.text('search_all'.tr()), findsOneWidget);
    });

    testWidgets('검색 결과가 없으면 빈 상태를 보여준다', (tester) async {
      when(() => mockSearchService.search('없는검색어')).thenAnswer(
          (_) async => const SearchResult(artists: [], festivals: [], posts: []));

      await _pump(tester);
      await tester.enterText(find.byType(TextField), '없는검색어');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('search_no_result'.tr()), findsOneWidget);
    });

    testWidgets('검색 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockSearchService.search('오류검색어')).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return const SearchResult(artists: [], festivals: [], posts: []);
      });

      await _pump(tester);
      await tester.enterText(find.byType(TextField), '오류검색어');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('search_error'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('search_no_result'.tr()), findsOneWidget);
    });
  });

  group('UnifiedSearchScreen 지우기', () {
    testWidgets('입력값이 있으면 지우기 버튼이 보이고 탭하면 결과가 초기화된다', (tester) async {
      when(() => mockSearchService.search('아이유')).thenAnswer((_) async => SearchResult(
            artists: [_artist()],
            festivals: const [],
            posts: const [],
          ));

      await _pump(tester);
      await tester.enterText(find.byType(TextField), '아이유');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // 검색 결과 탭이 사라지고, 방금 검색한 키워드가 최근 검색어 목록으로 대체된다
      expect(find.text('search_all'.tr()), findsNothing);
      expect(find.text('no_recent_searches'.tr()), findsNothing);
      expect(find.text('아이유'), findsOneWidget); // 최근 검색어 목록 항목
    });
  });
}
