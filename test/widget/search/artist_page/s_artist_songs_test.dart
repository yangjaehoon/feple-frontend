import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_songs.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_request_sheet.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSongService extends Mock implements SongService {}
class MockSongRequestService extends Mock implements SongRequestService {}
class MockUserProvider extends Mock implements UserProvider {}

SongModel _song({int id = 1, String title = '노래'}) => SongModel(
      id: id,
      title: title,
      youtubeVideoId: 'abc',
      youtubeUrl: 'https://youtube.com/watch?v=abc',
    );

void main() {
  late MockSongService mockSongService;

  setUp(() {
    mockSongService = MockSongService();
    if (sl.isRegistered<SongService>()) sl.unregister<SongService>();
    sl.registerSingleton<SongService>(mockSongService);
    if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
    sl.registerSingleton<SongRequestService>(MockSongRequestService());
  });

  tearDown(() {
    if (sl.isRegistered<SongService>()) sl.unregister<SongService>();
    if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
  });

  Future<void> pump(WidgetTester tester) async {
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
        child: ChangeNotifierProvider<UserProvider>.value(
          value: userProvider,
          child: CustomThemeHolder(
            theme: CustomTheme.light,
            changeTheme: (_) {},
            child: MaterialApp(
              home: ArtistSongsScreen(artistId: 1, artistName: '아티스트'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ArtistSongsScreen 렌더링', () {
    testWidgets('노래 목록을 보여준다', (tester) async {
      when(() => mockSongService.fetchSongs(1))
          .thenAnswer((_) async => [_song(title: '전체목록곡')]);

      await pump(tester);
      await tester.pump();

      expect(find.text('전체목록곡'), findsOneWidget);
    });

    testWidgets('노래가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_songs'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태를 보여준다', (tester) async {
      when(() => mockSongService.fetchSongs(1))
          .thenAnswer((_) async => throw Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('ArtistSongsScreen 새로고침', () {
    testWidgets('pull-to-refresh 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async {
        callCount++;
        return [];
      });

      await pump(tester);
      await tester.pump();
      expect(callCount, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();

      expect(callCount, 2);
    });
  });

  group('ArtistSongsScreen 신청', () {
    testWidgets('신청 버튼을 탭하면 신청 바텀시트가 열린다', (tester) async {
      when(() => mockSongService.fetchSongs(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('song_request_button'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(SongRequestSheet), findsOneWidget);
    });
  });
}
