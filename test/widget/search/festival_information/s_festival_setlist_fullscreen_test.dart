import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_setlist_fullscreen.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockFestivalDetailService extends Mock implements FestivalDetailService {}

class MockUserProvider extends Mock implements UserProvider {}

class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

SongModel _song({
  int id = 1,
  String title = '노래',
  String youtubeUrl = 'https://youtube.com/watch?v=abc123',
}) =>
    SongModel(id: id, title: title, youtubeVideoId: 'abc123', youtubeUrl: youtubeUrl);

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
  late FakeUrlLauncherPlatform fakeLauncher;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockService = MockFestivalDetailService();
    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(10);
    fakeLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeLauncher;
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
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: FestivalSetlistFullscreenScreen(festivalId: 1),
          ),
        ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FestivalSetlistFullscreenScreen 렌더링', () {
    testWidgets('아티스트 목록을 보여준다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistName: '아티스트A'), _entry(artistName: '아티스트B')]);

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('아티스트A'), findsOneWidget);
      expect(find.text('아티스트B'), findsOneWidget);
    });

    testWidgets('셋리스트가 없으면 빈 상태를 보여준다', (tester) async {
      when(() => mockService.fetchSetlist(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('no_setlist'.tr()), findsOneWidget);
    });
  });

  group('FestivalSetlistFullscreenScreen 확장/축소', () {
    testWidgets('아티스트 헤더를 탭하면 곡 목록이 펼쳐진다', (tester) async {
      when(() => mockService.fetchSetlist(1)).thenAnswer(
        (_) async => [_entry(artistName: '아티스트A', songs: [_song(title: '곡1')])],
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('곡1'), findsNothing);

      await tester.tap(find.text('아티스트A'));
      await tester.pump();

      expect(find.text('곡1'), findsOneWidget);
    });
  });

  group('FestivalSetlistFullscreenScreen 곡 탭', () {
    testWidgets('유효한 유튜브 URL이면 외부 실행을 시도한다', (tester) async {
      when(() => mockService.fetchSetlist(1)).thenAnswer(
        (_) async => [
          _entry(
            artistName: '아티스트A',
            songs: [_song(title: '곡1', youtubeUrl: 'https://youtube.com/watch?v=abc123')],
          ),
        ],
      );

      await pump(tester);
      await tester.pump();
      await tester.tap(find.text('아티스트A'));
      await tester.pump();

      await tester.tap(find.text('곡1'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, ['https://youtube.com/watch?v=abc123']);
    });

    testWidgets('유효하지 않은 URL이면 에러 스낵바를 보여주고 실행하지 않는다', (tester) async {
      when(() => mockService.fetchSetlist(1)).thenAnswer(
        (_) async => [
          _entry(
            artistName: '아티스트A',
            songs: [_song(title: '곡1', youtubeUrl: 'https://evil.example.com/x')],
          ),
        ],
      );

      await pump(tester);
      await tester.pump();
      await tester.tap(find.text('아티스트A'));
      await tester.pump();

      await tester.tap(find.text('곡1'));
      await tester.pumpAndSettle();

      expect(find.text('youtube_open_failed'.tr()), findsOneWidget);
      expect(fakeLauncher.launchedUrls, isEmpty);
    });
  });

  group('FestivalSetlistFullscreenScreen 신청', () {
    testWidgets('연필 아이콘을 탭하면 신청 시트가 열린다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistName: '아티스트A')]);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SetlistRequestSheet), findsOneWidget);
      expect(find.text('아티스트A'), findsWidgets);
    });
  });

  group('SetlistRequestSheet 제출', () {
    testWidgets('메시지를 입력하고 제출하면 성공 스낵바를 보여주고 시트가 닫힌다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistFestivalId: 5, artistName: '아티스트A')]);
      when(() => mockService.submitSetlistRequest(
            festivalId: 1,
            artistFestivalId: 5,
            message: '이 곡 틀어주세요',
          )).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '이 곡 틀어주세요');
      await tester.tap(find.text('setlist_request_submit'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockService.submitSetlistRequest(
            festivalId: 1,
            artistFestivalId: 5,
            message: '이 곡 틀어주세요',
          )).called(1);
      expect(find.text('setlist_request_sent'.tr()), findsOneWidget);
      expect(find.byType(SetlistRequestSheet), findsNothing);
    });

    testWidgets('제출 실패 시 에러 스낵바를 보여주고 시트는 유지된다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistFestivalId: 5, artistName: '아티스트A')]);
      when(() => mockService.submitSetlistRequest(
            festivalId: any(named: 'festivalId'),
            artistFestivalId: any(named: 'artistFestivalId'),
            message: any(named: 'message'),
          )).thenThrow(Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '요청 메시지');
      await tester.tap(find.text('setlist_request_submit'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('setlist_request_failed'.tr()), findsOneWidget);
      expect(find.byType(SetlistRequestSheet), findsOneWidget);
    });

    testWidgets('메시지가 비어있으면 제출되지 않는다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistFestivalId: 5, artistName: '아티스트A')]);

      await pump(tester);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('setlist_request_submit'.tr()));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.submitSetlistRequest(
            festivalId: any(named: 'festivalId'),
            artistFestivalId: any(named: 'artistFestivalId'),
            message: any(named: 'message'),
          ));
      expect(find.byType(SetlistRequestSheet), findsOneWidget);
    });

    testWidgets('취소 버튼을 탭하면 시트가 닫힌다', (tester) async {
      when(() => mockService.fetchSetlist(1))
          .thenAnswer((_) async => [_entry(artistFestivalId: 5, artistName: '아티스트A')]);

      await pump(tester);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(SetlistRequestSheet), findsNothing);
    });
  });
}
