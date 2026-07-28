import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_songs.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_songs.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSongService extends Mock implements SongService {}

SongModel _song({int id = 1, String title = '노래', int festivalCount = 0}) => SongModel(
      id: id,
      title: title,
      youtubeVideoId: 'abc',
      youtubeUrl: 'https://youtube.com/watch?v=abc',
      festivalCount: festivalCount,
    );

void main() {
  late MockSongService mockSongService;

  setUp(() {
    mockSongService = MockSongService();
    if (sl.isRegistered<SongService>()) sl.unregister<SongService>();
    sl.registerSingleton<SongService>(mockSongService);
  });

  tearDown(() {
    if (sl.isRegistered<SongService>()) sl.unregister<SongService>();
  });

  Future<void> pump(WidgetTester tester, {GlobalKey<ArtistSongsState>? key}) async {
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
              body: ArtistSongs(key: key, artistId: 1, artistName: '아티스트'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ArtistSongs 렌더링', () {
    testWidgets('노래 목록을 최대 5개까지 보여준다', (tester) async {
      when(() => mockSongService.fetchSongs(1)).thenAnswer(
        (_) async => List.generate(7, (i) => _song(id: i, title: '노래$i')),
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('노래0'), findsOneWidget);
      expect(find.text('노래4'), findsOneWidget);
      expect(find.text('노래5'), findsNothing);
    });

    testWidgets('노래가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_songs'.tr()), findsOneWidget);
    });
  });

  group('ArtistSongs 네비게이션', () {
    testWidgets('헤더를 탭하면 노래 전체 목록 화면으로 이동한다', (tester) async {
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('artist_songs_title'.tr(args: ['아티스트'])));
      await tester.pumpAndSettle();

      expect(find.byType(ArtistSongsScreen), findsOneWidget);
    });
  });

  group('ArtistSongs 새로고침', () {
    testWidgets('refresh를 호출하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });
      final key = GlobalKey<ArtistSongsState>();

      await pump(tester, key: key);
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
