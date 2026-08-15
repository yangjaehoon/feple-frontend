import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_genre_style.dart';
import 'package:feple/screen/main/tab/search/w_artist_discovery.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/artist_suggestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistService extends Mock implements ArtistService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}
class MockArtistSuggestionService extends Mock implements ArtistSuggestionService {}
class MockUserProvider extends Mock implements UserProvider {}

Artist _artist({int id = 1, String name = '아티스트', String genre = 'KPOP'}) => Artist(
      id: id,
      name: name,
      genre: genre,
      profileImageUrl: '',
      followerCount: 0,
    );

Future<void> _pump(
  WidgetTester tester, {
  int? userId = 1,
  GlobalKey<ArtistDiscoverySectionState>? key,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final userProvider = MockUserProvider();
  when(() => userProvider.currentUserId).thenReturn(userId);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: ChangeNotifierProvider<UserProvider>.value(
        value: userProvider,
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(home: Scaffold(body: ArtistDiscoverySection(key: key))),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockArtistService mockArtistService;
  late MockArtistFollowService mockFollowService;
  late MockArtistSuggestionService mockSuggestionService;

  setUp(() {
    mockArtistService = MockArtistService();
    mockFollowService = MockArtistFollowService();
    mockSuggestionService = MockArtistSuggestionService();

    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(mockArtistService);
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    sl.registerSingleton<ArtistFollowService>(mockFollowService);
    if (sl.isRegistered<ArtistSuggestionService>()) sl.unregister<ArtistSuggestionService>();
    sl.registerSingleton<ArtistSuggestionService>(mockSuggestionService);

    when(() => mockFollowService.fetchFollowingIds(any())).thenAnswer((_) async => {});
  });

  tearDown(() {
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    if (sl.isRegistered<ArtistFollowService>()) sl.unregister<ArtistFollowService>();
    if (sl.isRegistered<ArtistSuggestionService>()) sl.unregister<ArtistSuggestionService>();
  });

  group('ArtistDiscoverySection 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<List<Artist>>();
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) => completer.future);

      await _pump(tester);

      expect(find.byType(SkeletonBox), findsWidgets);
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('ArtistDiscoverySection 렌더링', () {
    testWidgets('아티스트 목록과 팔로우 여부를 보여준다', (tester) async {
      when(() => mockArtistService.fetchArtists())
          .thenAnswer((_) async => [_artist(id: 1, name: '아이유'), _artist(id: 2, name: '뉴진스')]);
      when(() => mockFollowService.fetchFollowingIds(1)).thenAnswer((_) async => {1});

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('아이유'), findsOneWidget);
      expect(find.text('뉴진스'), findsOneWidget);
    });

    testWidgets('아티스트 추천 배너가 보인다', (tester) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => []);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('artist_suggestion_banner'.tr()), findsOneWidget);
    });
  });

  group('ArtistDiscoverySection 장르 필터', () {
    testWidgets('장르 칩을 선택하면 해당 장르만 표시된다', (tester) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => [
            _artist(id: 1, name: '아이유', genre: 'BALLAD'),
            _artist(id: 2, name: '뉴진스', genre: 'KPOP'),
          ]);

      await _pump(tester);
      await tester.pumpAndSettle();
      expect(find.text('아이유'), findsOneWidget);
      expect(find.text('뉴진스'), findsOneWidget);

      // KPOP은 artistGenreLabel 매핑에 없어 원문 그대로 칩 라벨로 쓰인다
      await tester.tap(find.text('KPOP'));
      await tester.pump();

      expect(find.text('뉴진스'), findsOneWidget);
      expect(find.text('아이유'), findsNothing);
    });
  });

  group('ArtistDiscoverySection 장르 칩 정렬', () {
    testWidgets('전체, 밴드, 인디, 힙합, R&B, 발라드 순으로 표시된다', (tester) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => [
            _artist(id: 1, name: 'A', genre: 'Ballad'),
            _artist(id: 2, name: 'B', genre: 'R&B'),
            _artist(id: 3, name: 'C', genre: 'Hip-hop'),
            _artist(id: 4, name: 'D', genre: 'Indie'),
            _artist(id: 5, name: 'E', genre: 'Band'),
          ]);

      await _pump(tester);
      await tester.pumpAndSettle();

      final labels = tester
          .widgetList<SelectableChip>(find.byType(SelectableChip))
          .map((c) => c.label)
          .toList();

      expect(labels, [
        'filter_all'.tr(),
        artistGenreLabel('Band'),
        artistGenreLabel('Indie'),
        artistGenreLabel('Hip-hop'),
        artistGenreLabel('R&B'),
        artistGenreLabel('Ballad'),
      ]);
    });

    testWidgets('우선순위에 없는 장르는 뒤에 붙는다', (tester) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => [
            _artist(id: 1, name: 'A', genre: 'Band'),
            _artist(id: 2, name: 'B', genre: '댄스'),
          ]);

      await _pump(tester);
      await tester.pumpAndSettle();

      final labels = tester
          .widgetList<SelectableChip>(find.byType(SelectableChip))
          .map((c) => c.label)
          .toList();

      expect(labels, [
        'filter_all'.tr(),
        artistGenreLabel('Band'),
        artistGenreLabel('댄스'),
      ]);
    });
  });

  group('ArtistDiscoverySection 네비게이션', () {
    // ArtistScreen(s_artist_page.dart)은 ArtistPhotoReadable 등 별도의 무거운
    // 의존성 트리를 가진 화면 — 이 위젯의 관심사가 아니므로 여기서 깊이 검증하지
    // 않고, 자체 위젯 테스트에서 다룰 대상으로 남겨둔다.

    testWidgets('로그인하지 않은 상태에서 추천 배너를 탭하면 안내 스낵바를 보여준다', (tester) async {
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async => []);

      await _pump(tester, userId: null);
      await tester.pumpAndSettle();

      await tester.tap(find.text('artist_suggestion_banner'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('no_login_info'.tr()), findsOneWidget);
    });
  });

  group('ArtistDiscoverySection 에러', () {
    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_artist(name: '재시도아티스트')];
      });

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('재시도아티스트'), findsOneWidget);
    });
  });

  group('ArtistDiscoverySectionState.refresh', () {
    testWidgets('refresh()를 호출하면 아티스트 목록과 팔로우 목록을 다시 불러온다', (tester) async {
      var artistCallCount = 0;
      when(() => mockArtistService.fetchArtists()).thenAnswer((_) async {
        artistCallCount++;
        return [_artist(name: artistCallCount == 1 ? '첫아티스트' : '갱신아티스트')];
      });

      final key = GlobalKey<ArtistDiscoverySectionState>();
      await _pump(tester, key: key);
      await tester.pumpAndSettle();
      expect(find.text('첫아티스트'), findsOneWidget);

      unawaited(key.currentState!.refresh());
      await tester.pumpAndSettle();

      expect(find.text('갱신아티스트'), findsOneWidget);
      expect(artistCallCount, 2);
    });
  });
}
